import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405 });
  }

  try {
    const url = new URL(req.url);
    const webhookId = url.searchParams.get("id");

    if (!webhookId) {
      return new Response(JSON.stringify({ error: "Webhook ID required" }), {
        status: 400,
        headers: { "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: integration } = await supabase
      .from("integrations")
      .select("*")
      .eq("id", webhookId)
      .eq("integration_type", "webhook")
      .eq("is_active", true)
      .single();

    if (!integration) {
      return new Response(JSON.stringify({ error: "Webhook not found" }), {
        status: 404,
        headers: { "Content-Type": "application/json" },
      });
    }

    const payload = await req.json();

    // Log the event
    await supabase.from("integration_events").insert({
      integration_id: integration.id,
      event_type: "webhook_received",
      payload,
      status: "received",
    });

    // Check for matching automation triggers
    const { data: triggers } = await supabase
      .from("automation_triggers")
      .select("*, automations(*)")
      .eq("trigger_type", "webhook")
      .contains("config", { webhook_id: webhookId });

    // Process matching triggers (simplified)
    for (const trigger of triggers || []) {
      if (trigger.automations?.is_enabled) {
        await supabase.from("automation_executions").insert({
          automation_id: trigger.automation_id,
          trigger_data: { webhook: payload },
          status: "running",
          started_at: new Date().toISOString(),
        });
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
