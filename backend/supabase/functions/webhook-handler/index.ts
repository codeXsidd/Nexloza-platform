import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type, x-webhook-signature",
};

async function verifyHmacSignature(
  payload: string,
  signature: string,
  secret: string
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", key, encoder.encode(payload));
  const computed = Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
  // Constant-time comparison
  if (computed.length !== signature.length) return false;
  let mismatch = 0;
  for (let i = 0; i < computed.length; i++) {
    mismatch |= computed.charCodeAt(i) ^ signature.charCodeAt(i);
  }
  return mismatch === 0;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method not allowed", { status: 405, headers: corsHeaders });
  }

  try {
    const url = new URL(req.url);
    const webhookId = url.searchParams.get("id");

    if (!webhookId) {
      return new Response(JSON.stringify({ error: "Webhook ID required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
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
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const rawBody = await req.text();
    let payload: unknown;
    try {
      payload = JSON.parse(rawBody);
    } catch {
      return new Response(JSON.stringify({ error: "Invalid JSON payload" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify HMAC signature if the integration has a secret configured
    const webhookSecret = integration.config?.secret;
    if (webhookSecret) {
      const signature = req.headers.get("x-webhook-signature");
      if (!signature) {
        await supabase.from("integration_events").insert({
          integration_id: integration.id,
          event_type: "webhook_rejected",
          payload,
          status: "rejected",
          error_message: "Missing signature",
        });
        return new Response(
          JSON.stringify({ error: "Missing webhook signature" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
      const valid = await verifyHmacSignature(rawBody, signature, webhookSecret);
      if (!valid) {
        await supabase.from("integration_events").insert({
          integration_id: integration.id,
          event_type: "webhook_rejected",
          payload,
          status: "rejected",
          error_message: "Invalid signature",
        });
        return new Response(
          JSON.stringify({ error: "Invalid webhook signature" }),
          {
            status: 401,
            headers: { ...corsHeaders, "Content-Type": "application/json" },
          }
        );
      }
    }

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

    for (const trigger of triggers || []) {
      if (trigger.automations?.is_enabled) {
        await supabase.from("automation_executions").insert({
          automation_id: trigger.automation_id,
          trigger_id: trigger.id,
          trigger_data: { webhook: payload },
          status: "running",
          started_at: new Date().toISOString(),
        });
      }
    }

    return new Response(JSON.stringify({ success: true }), {
      status: 200,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
