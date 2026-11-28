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

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user }, error: authError } = await supabase.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { device_id, command_type, payload, command_id } = await req.json();

    if (!device_id || !command_type) {
      return new Response(
        JSON.stringify({ error: "device_id and command_type required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: device } = await supabase
      .from("devices")
      .select("id, project_id, is_virtual, projects(organization_id)")
      .eq("id", device_id)
      .single();

    if (!device) {
      return new Response(JSON.stringify({ error: "Device not found or access denied" }), {
        status: 404,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    if (command_id != null &&
        (typeof command_id !== "string" ||
         !/^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i.test(command_id))) {
      return Response.json({ error: "Invalid command ID" }, { status: 400, headers: corsHeaders });
    }
    if (device.is_virtual) {
      let capabilities = supabase.from("actuator_definitions")
        .select("control_type,min_value,max_value")
        .eq("device_id", device_id).eq("command_key", command_type).eq("is_active", true);
      if (payload?.actuator_id) capabilities = capabilities.eq("id", payload.actuator_id);
      const { data: actuator } = await capabilities.maybeSingle();
      const value = typeof payload?.value === "boolean" ? Number(payload.value) : payload?.value;
      if (!actuator || typeof value !== "number" || !Number.isFinite(value) ||
          value < (actuator.min_value ?? 0) || value > (actuator.max_value ?? 1) ||
          (actuator.control_type === "toggle" && value !== 0 && value !== 1)) {
        return Response.json({ error: "Unsupported actuator value" }, { status: 400, headers: corsHeaders });
      }
    }

    const { data: queued, error: cmdError } = await supabase
      .from("device_commands")
      .insert({
        ...(command_id ? { id: command_id } : {}),
        device_id, issued_by: user.id, command_type, payload: payload || {},
        status: "pending",
        expires_at: new Date(Date.now() + 30000).toISOString(),
      })
      .select().single();
    let command = queued;
    if (cmdError?.code === "23505" && command_id) {
      const { data: previous } = await supabase.from("device_commands").select()
        .eq("id", command_id).eq("issued_by", user.id).eq("device_id", device_id)
        .eq("command_type", command_type).maybeSingle();
      if (previous && Object.keys(previous.payload).length === Object.keys(payload || {}).length &&
          Object.entries(payload || {}).every(([name, value]) =>
            JSON.stringify(previous.payload[name]) === JSON.stringify(value))) {
        command = previous;
      } else {
        return Response.json({ error: "Command ID is already in use" }, { status: 409, headers: corsHeaders });
      }
    }
    if (!command) {
      return Response.json({ error: "Command could not be queued" }, {
        status: cmdError?.code === "42501" ? 403 : 500, headers: corsHeaders,
      });
    }

    const orgId = (device as any).projects?.organization_id ?? "default";
    const mqttTopic = `nexloza/v1/${orgId}/${device.project_id}/${device_id}/command`;

    return new Response(
      JSON.stringify({
        command,
        mqtt: device.is_virtual ? null : {
          topic: mqttTopic,
          payload: {
            command_id: command.id,
            command_type,
            payload: payload || {},
          },
        },
      }),
      {
        status: 201,
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
