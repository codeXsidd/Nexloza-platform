import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const uuid = /^[0-9a-f]{8}-(?:[0-9a-f]{4}-){3}[0-9a-f]{12}$/i;
const reply = (status: number, data: object) => Response.json(data, { status });

serve(async (request) => {
  if (request.method !== "POST") return reply(405, { error: "POST required" });
  try {
    const key = request.headers.get("x-api-key");
    const secret = request.headers.get("x-api-secret");
    if (!key || !secret) return reply(401, { error: "Device credentials required" });

    const gateway = Deno.env.get("SUPABASE_URL")!;
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const database = createClient(gateway, serviceKey);
    const { data: credential, error: lookupError } = await database
      .from("device_credentials")
      .select("device_id, secret_hash, expires_at, devices(is_virtual)")
      .eq("api_key", key)
      .eq("is_active", true)
      .maybeSingle();
    if (lookupError) return reply(503, { error: "Credential verification unavailable" });
    if (!credential || !credential.devices?.is_virtual ||
        (credential.expires_at && Date.parse(credential.expires_at) <= Date.now())) {
      return reply(401, { error: "Invalid virtual device credentials" });
    }
    const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(secret));
    const hash = Array.from(new Uint8Array(digest))
      .map((byte) => byte.toString(16).padStart(2, "0")).join("");
    const expected = credential.secret_hash;
    let mismatch = hash.length ^ expected.length;
    for (let i = 0; i < hash.length; i++) {
      mismatch |= hash.charCodeAt(i) ^ (expected.charCodeAt(i) || 0);
    }
    if (mismatch !== 0) return reply(401, { error: "Invalid virtual device credentials" });

    const body = await request.json();
    const device = credential.device_id;
    if (body.device_id !== device) return reply(403, { error: "Device mismatch" });
    switch (body.action) {
      case "dispatch": {
        const { data, error } = await database.rpc("dispatch_virtual_commands", { p_device: device });
        return error ? reply(503, { error: "Dispatch unavailable" }) : reply(200, { commands: data });
      }
      case "ack": {
        if (!uuid.test(body.command_id ?? "") || typeof body.success !== "boolean" ||
            (body.success && (typeof body.value !== "number" || !Number.isFinite(body.value)))) {
          return reply(400, { error: "Invalid acknowledgement" });
        }
        const { data, error } = await database.rpc("complete_virtual_command", {
          p_device: device, p_command: body.command_id, p_success: body.success,
          p_value: body.success ? body.value : null,
        });
        return error ? reply(503, { error: "Acknowledgement unavailable" })
          : data ? reply(200, { success: true }) : reply(409, { error: "Command cannot be completed" });
      }
      case "availability": {
        if (typeof body.online !== "boolean") return reply(400, { error: "Invalid availability" });
        const { error } = await database.from("devices").update({
          is_online: body.online, ...(body.online ? { last_seen_at: new Date().toISOString() } : {}),
        }).eq("id", device);
        return error ? reply(503, { error: "Availability unavailable" }) : reply(200, { success: true });
      }
      default: return reply(400, { error: "Unknown runtime action" });
    }
  } catch (_) {
    return reply(400, { error: "Invalid runtime request" });
  }
});
