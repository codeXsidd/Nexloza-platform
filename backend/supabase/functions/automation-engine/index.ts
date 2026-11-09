import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const body = await req.json();
    const { device_id, sensor_key, value } = body;

    if (!device_id || typeof device_id !== "string") {
      return new Response(
        JSON.stringify({ error: "device_id (string) required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (!sensor_key || typeof sensor_key !== "string") {
      return new Response(
        JSON.stringify({ error: "sensor_key (string) required" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (typeof value !== "number" || !isFinite(value)) {
      return new Response(
        JSON.stringify({ error: "value must be a finite number" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: device } = await supabase
      .from("devices")
      .select("id, project_id")
      .eq("id", device_id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Device not found" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
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
      if (
        op === "between" &&
        value >= config.low &&
        value <= config.high
      )
        shouldFire = true;

      if (shouldFire) {
        const automation = trigger.automations;

        // Check cooldown
        const cooldownSec = automation.cooldown_seconds ?? 60;
        const { data: recentExec } = await supabase
          .from("automation_executions")
          .select("id")
          .eq("automation_id", automation.id)
          .gte(
            "started_at",
            new Date(Date.now() - cooldownSec * 1000).toISOString()
          )
          .limit(1);

        if (recentExec && recentExec.length > 0) continue;

        // Check max executions per hour
        const maxPerHour = automation.max_executions_per_hour ?? 60;
        const { count: hourlyCount } = await supabase
          .from("automation_executions")
          .select("id", { count: "exact", head: true })
          .eq("automation_id", automation.id)
          .gte(
            "started_at",
            new Date(Date.now() - 3600000).toISOString()
          );

        if (hourlyCount !== null && hourlyCount >= maxPerHour) continue;

        // Execute automation — load actions and mark execution
        const { data: actions } = await supabase
          .from("automation_actions")
          .select("*")
          .eq("automation_id", automation.id)
          .order("sort_order");

        const actionsExecuted = [];
        for (const action of actions || []) {
          try {
            if (action.action_type === "device_command" && action.config?.device_id) {
              await supabase.from("device_commands").insert({
                device_id: action.config.device_id,
                command_type: action.config.command_type || "custom",
                payload: action.config.payload || {},
                status: "pending",
                expires_at: new Date(Date.now() + 30000).toISOString(),
              });
            } else if (action.action_type === "notification" && action.config?.message) {
              await supabase.from("notifications").insert({
                user_id: null,
                project_id: automation.project_id,
                title: action.config.title || "Automation Alert",
                body: action.config.message,
                category: "automation",
                severity: action.config.severity || "info",
              });
            }
            actionsExecuted.push({
              action_id: action.id,
              action_type: action.action_type,
              status: "completed",
              executed_at: new Date().toISOString(),
            });
          } catch (actionErr) {
            actionsExecuted.push({
              action_id: action.id,
              action_type: action.action_type,
              status: "failed",
              error: String(actionErr),
              executed_at: new Date().toISOString(),
            });
          }
        }

        const startedAt = new Date().toISOString();
        await supabase.from("automation_executions").insert({
          automation_id: automation.id,
          trigger_id: trigger.id,
          trigger_data: { device_id, sensor_key, value },
          status: "completed",
          started_at: startedAt,
          completed_at: new Date().toISOString(),
          actions_executed: actionsExecuted,
        });

        // Update automation execution count
        await supabase
          .from("automations")
          .update({
            execution_count: automation.execution_count + 1,
            last_executed_at: startedAt,
          })
          .eq("id", automation.id);

        executedAutomations.push(automation.id);
      }
    }

    return new Response(
      JSON.stringify({
        processed: true,
        executions: executedAutomations.length,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
