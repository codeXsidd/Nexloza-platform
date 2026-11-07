import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-api-key, x-api-secret, content-type",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const apiKey = req.headers.get("x-api-key");
    const apiSecret = req.headers.get("x-api-secret");

    if (!apiKey || !apiSecret) {
      return new Response(JSON.stringify({ error: "Missing credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const { data: cred, error } = await supabase
      .from("device_credentials")
      .select("*, devices(*)")
      .eq("api_key", apiKey)
      .eq("is_active", true)
      .single();

    if (error || !cred) {
      return new Response(JSON.stringify({ error: "Invalid credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Verify secret hash (in production, use bcrypt or argon2)
    const encoder = new TextEncoder();
    const data = encoder.encode(apiSecret);
    const hashBuffer = await crypto.subtle.digest("SHA-256", data);
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
      return new Response(JSON.stringify({ error: "Invalid credentials" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Update device last_seen
    await supabase
      .from("devices")
      .update({ last_seen_at: new Date().toISOString(), is_online: true })
      .eq("id", cred.device_id);

    const device = cred.devices;

    return new Response(
      JSON.stringify({
        device_id: device.id,
        project_id: device.project_id,
        mqtt: {
          client_id: `nexloza_${device.id}`,
          username: device.id,
          topics: {
            telemetry: `nexloza/${device.project_id}/${device.id}/telemetry`,
            commands: `nexloza/${device.project_id}/${device.id}/commands`,
            state: `nexloza/${device.project_id}/${device.id}/state`,
            heartbeat: `nexloza/${device.project_id}/${device.id}/heartbeat`,
          },
        },
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
