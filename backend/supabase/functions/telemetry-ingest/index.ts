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
    const body = await req.json();
    const { device_id, readings } = body;

    if (!device_id || !readings || !Array.isArray(readings)) {
      return new Response(
        JSON.stringify({ error: "Invalid payload: device_id and readings[] required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // Verify device exists
    const { data: device, error: deviceError } = await supabase
      .from("devices")
      .select("id, project_id")
      .eq("id", device_id)
      .single();

    if (deviceError || !device) {
      return new Response(
        JSON.stringify({ error: "Device not found" }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Insert telemetry readings
    const telemetryRows = readings.map((r: any) => ({
      device_id,
      sensor_key: r.key,
      value_numeric: typeof r.value === "number" ? r.value : null,
      value_text: typeof r.value === "string" ? r.value : null,
      value_json: typeof r.value === "object" ? r.value : null,
      recorded_at: r.timestamp || new Date().toISOString(),
    }));

    const { error: insertError } = await supabase
      .from("telemetry")
      .insert(telemetryRows);

    if (insertError) {
      return new Response(
        JSON.stringify({ error: "Failed to insert telemetry" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    // Update device last_seen
    await supabase
      .from("devices")
      .update({ last_seen_at: new Date().toISOString(), is_online: true })
      .eq("id", device_id);

    return new Response(
      JSON.stringify({ success: true, count: telemetryRows.length }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: "Internal server error" }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
