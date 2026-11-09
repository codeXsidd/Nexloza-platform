import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

const SYSTEM_PROMPT = `You are Nexloza AI Assistant — an expert IoT assistant built into the Nexloza platform.
You help users understand their IoT devices, sensor readings, automations, and troubleshoot issues.
You can analyze telemetry data, suggest automations, generate firmware code, and explain device connectivity.
Always be helpful, concise, and safety-conscious. Never execute destructive actions without user confirmation.
When generating code, use proper Arduino/PlatformIO syntax for ESP32/ESP8266.`;

async function callBedrock(
  messages: { role: string; content: string }[],
  systemPrompt: string
): Promise<string> {
  const region = Deno.env.get("BEDROCK_REGION") || "us-east-1";
  const modelId =
    Deno.env.get("BEDROCK_MODEL_ID") || "us.anthropic.claude-sonnet-4-20250514";
  const accessKey = Deno.env.get("AWS_ACCESS_KEY_ID");
  const secretKey = Deno.env.get("AWS_SECRET_ACCESS_KEY");

  if (!accessKey || !secretKey) {
    throw new Error("BEDROCK_NOT_CONFIGURED");
  }

  const endpoint = `https://bedrock-runtime.${region}.amazonaws.com/model/${modelId}/invoke`;
  const body = JSON.stringify({
    anthropic_version: "bedrock-2023-05-31",
    max_tokens: 2048,
    system: systemPrompt,
    messages: messages.map((m) => ({ role: m.role, content: m.content })),
  });

  const response = await fetch(endpoint, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-Amz-Content-Sha256": "UNSIGNED-PAYLOAD",
    },
    body,
  });

  if (!response.ok) {
    throw new Error(`Bedrock API error: ${response.status}`);
  }

  const data = await response.json();
  return data.content?.[0]?.text || "No response generated.";
}

async function callGrok(
  messages: { role: string; content: string }[],
  systemPrompt: string
): Promise<string> {
  const apiKey = Deno.env.get("XAI_API_KEY");
  if (!apiKey) {
    throw new Error("GROK_NOT_CONFIGURED");
  }

  const model = Deno.env.get("XAI_MODEL_ID") || "grok-3";

  const response = await fetch("https://api.x.ai/v1/chat/completions", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model,
      messages: [{ role: "system", content: systemPrompt }, ...messages],
      max_tokens: 2048,
    }),
  });

  if (!response.ok) {
    const err = await response.text();
    throw new Error(`Grok API error: ${response.status} — ${err}`);
  }

  const data = await response.json();
  return data.choices?.[0]?.message?.content || "No response generated.";
}

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

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), {
        status: 401,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { message, conversation_id, project_id, provider } = await req.json();

    if (!message) {
      return new Response(JSON.stringify({ error: "message required" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const selectedProvider = provider || "claude";

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
        projectContext = `\nUser's project: ${project.name} (${project.category}). ${project.description || ""}`;
      }
      if (devices && devices.length > 0) {
        projectContext += `\nDevices: ${devices
          .map(
            (d: any) =>
              `${d.name} (${d.hardware_platform}, ${d.is_online ? "online" : "offline"})`
          )
          .join(", ")}`;
      }
    }

    const systemPrompt = SYSTEM_PROMPT + projectContext;

    let conversationMessages: { role: string; content: string }[] = [];
    const serviceClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    if (conversation_id) {
      const { data: history } = await serviceClient
        .from("ai_messages")
        .select("role, content")
        .eq("conversation_id", conversation_id)
        .order("created_at")
        .limit(20);
      if (history) {
        conversationMessages = history.filter(
          (m: any) => m.role === "user" || m.role === "assistant"
        );
      }
    }

    conversationMessages.push({ role: "user", content: message });

    let assistantContent: string;
    let actualProvider = selectedProvider;

    try {
      if (selectedProvider === "grok") {
        assistantContent = await callGrok(conversationMessages, systemPrompt);
      } else {
        assistantContent = await callBedrock(conversationMessages, systemPrompt);
      }
    } catch (err: any) {
      if (
        err.message === "BEDROCK_NOT_CONFIGURED" ||
        err.message === "GROK_NOT_CONFIGURED"
      ) {
        const providerName =
          selectedProvider === "grok" ? "Grok (xAI)" : "Claude (Bedrock)";
        assistantContent = `${providerName} is not configured yet. To enable AI responses:\n\n`;
        if (selectedProvider === "grok") {
          assistantContent +=
            "1. Get an API key from the xAI console\n" +
            "2. Set XAI_API_KEY in your Supabase Edge Function secrets\n" +
            "3. Optionally set XAI_MODEL_ID (default: grok-3)";
        } else {
          assistantContent +=
            "1. Configure AWS credentials: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY\n" +
            "2. Set BEDROCK_REGION (default: us-east-1)\n" +
            "3. Set BEDROCK_MODEL_ID (default: claude-sonnet-4-20250514)";
        }
        actualProvider = "fallback";
      } else {
        assistantContent = "Sorry, the AI service is temporarily unavailable. Please try again later.";
        actualProvider = "error";
      }
    }

    let convId = conversation_id;
    if (!convId) {
      const { data: conv } = await serviceClient
        .from("ai_conversations")
        .insert({
          user_id: user.id,
          project_id,
          title: message.substring(0, 100),
          model_id: actualProvider,
        })
        .select()
        .single();
      convId = conv?.id;
    }

    if (convId) {
      await serviceClient.from("ai_messages").insert([
        { conversation_id: convId, role: "user", content: message },
        { conversation_id: convId, role: "assistant", content: assistantContent },
      ]);
    }

    return new Response(
      JSON.stringify({
        conversation_id: convId,
        role: "assistant",
        content: assistantContent,
        provider: actualProvider,
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
