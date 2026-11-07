import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

const BEDROCK_REGION = Deno.env.get("BEDROCK_REGION") || "us-east-1";
const BEDROCK_MODEL = Deno.env.get("BEDROCK_MODEL_ID") || "us.anthropic.claude-sonnet-4-20250514";

const SYSTEM_PROMPT = `You are Nexloza AI Assistant — an expert IoT assistant built into the Nexloza platform.
You help users understand their IoT devices, sensor readings, automations, and troubleshoot issues.
You can analyze telemetry data, suggest automations, generate firmware code, and explain device connectivity.
Always be helpful, concise, and safety-conscious. Never execute destructive actions without user confirmation.`;

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

    const { data: { user } } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { message, conversation_id, project_id } = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: "message required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    // Get project context if specified
    let projectContext = "";
    if (project_id) {
      const { data: project } = await supabase
        .from("projects")
        .select("name, category, description")
        .eq("id", project_id)
        .single();

      const { data: devices } = await supabase
        .from("devices")
        .select("name, device_type, hardware_platform, is_online")
        .eq("project_id", project_id)
        .limit(20);

      if (project) {
        projectContext = `\nUser's project: ${project.name} (${project.category}). `;
        projectContext += `${project.description || ""}`;
      }
      if (devices && devices.length > 0) {
        projectContext += `\nDevices: ${devices.map(
          (d: any) => `${d.name} (${d.hardware_platform}, ${d.is_online ? "online" : "offline"})`
        ).join(", ")}`;
      }
    }

    // Call Bedrock (requires AWS credentials configured on the server)
    // This is a placeholder — actual Bedrock integration requires AWS SDK
    const response = {
      role: "assistant",
      content: `I'm the Nexloza AI Assistant. To enable AI responses, configure AWS Bedrock credentials (BEDROCK_REGION, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) in your backend environment. Model: ${BEDROCK_MODEL}.\n\nYour question: "${message}"${projectContext ? `\n\nProject context loaded.` : ""}`,
    };

    // Store message in database
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    let convId = conversation_id;
    if (!convId) {
      const { data: conv } = await serviceClient
        .from("ai_conversations")
        .insert({ user_id: user.id, project_id, title: message.substring(0, 100) })
        .select()
        .single();
      convId = conv?.id;
    }

    if (convId) {
      await serviceClient.from("ai_messages").insert([
        { conversation_id: convId, role: "user", content: message },
        { conversation_id: convId, role: "assistant", content: response.content },
      ]);
    }

    return new Response(
      JSON.stringify({ conversation_id: convId, ...response }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: "Internal server error" }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
