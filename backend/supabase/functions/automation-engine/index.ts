import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { status: 200 });
  }

  try {
    const { device_id, sensor_key, value } = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Get device info
    const { data: device } = await supabase
      .from("devices")
      .select("id, project_id")
      .eq("id", device_id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Device not found" }), {
        status: 404, headers: { "Content-Type": "application/json" },
      });
    }

    // Find matching automations with sensor_threshold triggers
    const { data: triggers } = await supabase
      .from("automation_triggers")
      .select("*, automations!inner(*)")
      .eq("trigger_type", "sensor_threshold")
      .eq("automations.project_id", device.project_id)
      .eq("automations.is_enabled", true);

    const executedAutomations: string[] = [];

    for (const trigger of triggers || []) {
      const config = trigger.config;
      if (config.sensor_key !== sensor_key) continue;
      if (config.device_id && config.device_id !== device_id) continue;

      let shouldFire = false;
      const op = config.operator;
      const threshold = config.threshold;

      if (op === "gt" && value > threshold) shouldFire = true;
      if (op === "lt" && value < threshold) shouldFire = true;
      if (op === "eq" && value === threshold) shouldFire = true;
      if (op === "gte" && value >= threshold) shouldFire = true;
      if (op === "lte" && value <= threshold) shouldFire = true;
      if (op === "between" && value >= config.low && value <= config.high) shouldFire = true;

      if (shouldFire) {
        // Check cooldown
        const automation = trigger.automations;
        const { data: recentExec } = await supabase
          .from("automation_executions")
          .select("id")
          .eq("automation_id", automation.id)
          .gte("started_at", new Date(Date.now() - automation.cooldown_seconds * 1000).toISOString())
          .limit(1);

        if (recentExec && recentExec.length > 0) continue;

        // Execute automation
        await supabase.from("automation_executions").insert({
          automation_id: automation.id,
          trigger_data: { device_id, sensor_key, value },
          status: "completed",
          started_at: new Date().toISOString(),
          completed_at: new Date().toISOString(),
        });

        executedAutomations.push(automation.id);
      }
    }

    return new Response(
      JSON.stringify({ processed: true, executions: executedAutomations.length }),
      { status: 200, headers: { "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500, headers: { "Content-Type": "application/json" },
    });
  }
});
