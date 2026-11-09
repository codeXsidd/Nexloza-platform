import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-api-key, x-api-secret, content-type",
};

const MAX_READINGS_PER_REQUEST = 100;
const MAX_SENSOR_KEY_LENGTH = 128;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const apiKey = req.headers.get("x-api-key");
    const apiSecret = req.headers.get("x-api-secret");

    if (!apiKey || !apiSecret) {
      return new Response(
        JSON.stringify({ error: "Missing device credentials" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Authenticate device via API key + secret hash
    const { data: cred, error: credError } = await supabase
      .from("device_credentials")
      .select("device_id, secret_hash, devices(id, project_id)")
      .eq("api_key", apiKey)
      .eq("is_active", true)
      .single();

    if (credError || !cred) {
      return new Response(
        JSON.stringify({ error: "Invalid device credentials" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Verify secret hash
    const encoder = new TextEncoder();
    const hashBuffer = await crypto.subtle.digest(
      "SHA-256",
      encoder.encode(apiSecret)
    );
    const hashHex = Array.from(new Uint8Array(hashBuffer))
      .map((b) => b.toString(16).padStart(2, "0"))
      .join("");

    // Constant-time comparison to prevent timing attacks
    const expected = cred.secret_hash;
    let mismatch = hashHex.length !== expected.length ? 1 : 0;
    for (let i = 0; i < hashHex.length; i++) {
      mismatch |= hashHex.charCodeAt(i) ^ (expected.charCodeAt(i) || 0);
    }
    if (mismatch !== 0) {
      return new Response(
        JSON.stringify({ error: "Invalid device credentials" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const device = cred.devices as { id: string; project_id: string };
    const deviceId = device.id;

    // Parse and validate payload
    const body = await req.json();
    const { readings } = body;

    if (!readings || !Array.isArray(readings) || readings.length === 0) {
      return new Response(
        JSON.stringify({ error: "readings[] required and must be non-empty" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    if (readings.length > MAX_READINGS_PER_REQUEST) {
      return new Response(
        JSON.stringify({
          error: `Max ${MAX_READINGS_PER_REQUEST} readings per request`,
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Check rate limit
    const { data: withinLimit } = await supabase.rpc(
      "check_telemetry_rate_limit",
      { p_device_id: deviceId }
    );
    if (withinLimit === false) {
      return new Response(
        JSON.stringify({ error: "Rate limit exceeded" }),
        {
          status: 429,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Validate and build telemetry rows
    const telemetryRows = [];
    for (const r of readings) {
      if (!r.key || typeof r.key !== "string") continue;
      if (r.key.length > MAX_SENSOR_KEY_LENGTH) continue;
      if (r.value === undefined || r.value === null) continue;

      telemetryRows.push({
        device_id: deviceId,
        sensor_key: r.key,
        value_numeric: typeof r.value === "number" ? r.value : null,
        value_text: typeof r.value === "string" ? r.value : null,
        value_json: typeof r.value === "object" ? r.value : null,
        recorded_at: r.timestamp || new Date().toISOString(),
      });
    }

    if (telemetryRows.length === 0) {
      return new Response(
        JSON.stringify({ error: "No valid readings in payload" }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    const { error: insertError } = await supabase
      .from("telemetry")
      .insert(telemetryRows);

    if (insertError) {
      return new Response(
        JSON.stringify({ error: "Failed to insert telemetry" }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        }
      );
    }

    // Update device last_seen and credential last_used
    await Promise.all([
      supabase
        .from("devices")
        .update({ last_seen_at: new Date().toISOString(), is_online: true })
        .eq("id", deviceId),
      supabase
        .from("device_credentials")
        .update({ last_used_at: new Date().toISOString() })
        .eq("api_key", apiKey),
    ]);

    return new Response(
      JSON.stringify({ success: true, count: telemetryRows.length }),
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
