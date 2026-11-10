import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2.39.0";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(JSON.stringify(data), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

// ---------------------------------------------------------------------------
// Escalation scheduler — process pending escalation tasks
// ---------------------------------------------------------------------------

async function processEscalationTasks(supabase: SupabaseClient): Promise<number> {
  const now = new Date().toISOString();

  const { data: tasks } = await supabase
    .from("escalation_tasks")
    .select("*, escalation_stages(*), alarms(*)")
    .eq("status", "pending")
    .lte("scheduled_at", now)
    .order("scheduled_at")
    .limit(50);

  if (!tasks || tasks.length === 0) return 0;

  let processed = 0;

  for (const task of tasks) {
    const alarm = task.alarms;
    const stage = task.escalation_stages;

    // Skip if alarm is already cleared
    if (!alarm || alarm.status === "cleared") {
      await supabase
        .from("escalation_tasks")
        .update({ status: "cancelled", executed_at: now })
        .eq("id", task.id);
      continue;
    }

    try {
      if (stage.action_type === "notify") {
        // Create notifications for each target
        const targets = stage.notification_targets as string[] || [];
        for (const userId of targets) {
          // Validate target is a project member
          const { data: member } = await supabase
            .from("project_members")
            .select("id")
            .eq("project_id", alarm.project_id)
            .eq("user_id", userId)
            .limit(1);

          const isOwner = await supabase
            .from("projects")
            .select("id")
            .eq("id", alarm.project_id)
            .eq("owner_id", userId)
            .limit(1);

          if ((!member || member.length === 0) && (!isOwner.data || isOwner.data.length === 0)) {
            continue;
          }

          // Check quiet hours
          const { data: prefs } = await supabase
            .from("notification_preferences")
            .select("*")
            .eq("user_id", userId)
            .eq("category", "alert")
            .limit(1);

          const pref = prefs?.[0];
          if (pref?.quiet_hours_enabled && pref.quiet_hours_start && pref.quiet_hours_end) {
            const tz = pref.timezone || "UTC";
            const nowLocal = new Date().toLocaleTimeString("en-US", {
              timeZone: tz,
              hour12: false,
              hour: "2-digit",
              minute: "2-digit",
            });
            const start = pref.quiet_hours_start.substring(0, 5);
            const end = pref.quiet_hours_end.substring(0, 5);
            if (start <= end) {
              if (nowLocal >= start && nowLocal <= end) continue;
            } else {
              if (nowLocal >= start || nowLocal <= end) continue;
            }
          }

          const { data: notification } = await supabase
            .from("notifications")
            .insert({
              user_id: userId,
              project_id: alarm.project_id,
              title: `Escalation: ${alarm.title}`,
              body: `Alarm "${alarm.title}" has been escalated to stage ${stage.stage_number}. Severity: ${alarm.severity}.`,
              category: "alert",
              severity: alarm.severity === "critical" || alarm.severity === "high" ? "critical" : "warning",
              alarm_id: alarm.id,
              navigation_target: `/alarms/${alarm.id}`,
            })
            .select("id")
            .single();

          // Create outbox entry for reliable delivery
          if (notification) {
            const idempotencyKey = `esc:${task.id}:${userId}:${stage.stage_number}`;
            await supabase.from("notification_outbox").insert({
              notification_id: notification.id,
              channel: "in_app",
              recipient_user_id: userId,
              payload: { alarm_id: alarm.id, stage: stage.stage_number },
              idempotency_key: idempotencyKey,
              status: "delivered",
              attempts: 1,
              last_attempt_at: now,
            }).onConflict("idempotency_key");
          }
        }
      } else if (stage.action_type === "auto_acknowledge") {
        if (alarm.status === "active") {
          await supabase
            .from("alarms")
            .update({
              status: "acknowledged",
              acknowledged_at: now,
            })
            .eq("id", alarm.id);

          await supabase.from("alarm_activity").insert({
            alarm_id: alarm.id,
            activity_type: "acknowledged",
            comment: `Auto-acknowledged by escalation policy stage ${stage.stage_number}`,
            data: { source: "escalation", task_id: task.id },
          });
        }
      }

      // Update alarm escalation state
      await supabase
        .from("alarms")
        .update({
          escalation_stage: stage.stage_number,
          escalated_at: now,
        })
        .eq("id", alarm.id);

      await supabase.from("alarm_activity").insert({
        alarm_id: alarm.id,
        activity_type: "escalated",
        comment: `Escalated to stage ${stage.stage_number}`,
        data: { stage_number: stage.stage_number, action_type: stage.action_type },
      });

      // Mark task as executed
      await supabase
        .from("escalation_tasks")
        .update({
          status: "executed",
          executed_at: now,
          result: { action_type: stage.action_type, targets_notified: stage.notification_targets?.length || 0 },
        })
        .eq("id", task.id);

      // Schedule next stage if exists
      const { data: nextStages } = await supabase
        .from("escalation_stages")
        .select("*")
        .eq("policy_id", task.policy_id)
        .eq("stage_number", stage.stage_number + 1)
        .limit(1);

      if (nextStages && nextStages.length > 0) {
        const nextStage = nextStages[0];
        const scheduledAt = new Date(Date.now() + nextStage.delay_minutes * 60000).toISOString();
        await supabase.from("escalation_tasks").insert({
          alarm_id: alarm.id,
          policy_id: task.policy_id,
          stage_id: nextStage.id,
          scheduled_at: scheduledAt,
          status: "pending",
        });
      }

      processed++;
    } catch (err) {
      await supabase
        .from("escalation_tasks")
        .update({
          status: "executed",
          executed_at: now,
          result: { error: String(err) },
        })
        .eq("id", task.id);
    }
  }

  return processed;
}

// ---------------------------------------------------------------------------
// Notification outbox processor — retry failed deliveries
// ---------------------------------------------------------------------------

async function processNotificationOutbox(supabase: SupabaseClient): Promise<number> {
  const now = new Date().toISOString();

  // Get pending or retryable entries
  const { data: entries } = await supabase
    .from("notification_outbox")
    .select("*")
    .or(`status.eq.pending,and(status.eq.failed,next_retry_at.lte.${now})`)
    .order("created_at")
    .limit(100);

  if (!entries || entries.length === 0) return 0;

  let processed = 0;

  for (const entry of entries) {
    try {
      // Mark as processing
      await supabase
        .from("notification_outbox")
        .update({ status: "processing", last_attempt_at: now })
        .eq("id", entry.id);

      if (entry.channel === "in_app") {
        // In-app notifications are already in the notifications table
        await supabase
          .from("notification_outbox")
          .update({
            status: "delivered",
            attempts: (entry.attempts || 0) + 1,
            last_attempt_at: now,
          })
          .eq("id", entry.id);
        processed++;
      } else if (entry.channel === "email") {
        // Email delivery is a stub — not production-ready without a real email provider
        // A notification recorded in the database is NOT proof that an email reached a user's device
        await supabase
          .from("notification_outbox")
          .update({
            status: "delivered",
            attempts: (entry.attempts || 0) + 1,
            last_attempt_at: now,
            error_message: "Email provider not configured — in-app delivery only",
          })
          .eq("id", entry.id);
        processed++;
      } else if (entry.channel === "push") {
        // Push delivery is a stub — not production-ready without a real push provider
        // A notification recorded in the database is NOT proof that a push notification reached a user's device
        await supabase
          .from("notification_outbox")
          .update({
            status: "delivered",
            attempts: (entry.attempts || 0) + 1,
            last_attempt_at: now,
            error_message: "Push provider not configured — in-app delivery only",
          })
          .eq("id", entry.id);
        processed++;
      }
    } catch (err) {
      const attempts = (entry.attempts || 0) + 1;
      const maxAttempts = entry.max_attempts || 3;

      if (attempts >= maxAttempts) {
        // Dead letter
        await supabase
          .from("notification_outbox")
          .update({
            status: "dead_letter",
            attempts,
            last_attempt_at: now,
            error_message: String(err),
          })
          .eq("id", entry.id);
      } else {
        // Schedule retry with exponential backoff
        const backoffMs = Math.min(300000, 1000 * Math.pow(2, attempts));
        const nextRetry = new Date(Date.now() + backoffMs).toISOString();
        await supabase
          .from("notification_outbox")
          .update({
            status: "failed",
            attempts,
            last_attempt_at: now,
            next_retry_at: nextRetry,
            error_message: String(err),
          })
          .eq("id", entry.id);
      }
    }
  }

  return processed;
}

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response(null, { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    const userClient = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } }
    );

    const { data: { user } } = await userClient.auth.getUser();
    if (!user) {
      return jsonResponse({ error: "Unauthorized" }, 401);
    }

    // Service-role client for server-side operations
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    const body = await req.json();
    const action = body.action as string;

    if (action === "process_escalations") {
      const count = await processEscalationTasks(supabase);
      return jsonResponse({ processed: count });
    }

    if (action === "process_outbox") {
      const count = await processNotificationOutbox(supabase);
      return jsonResponse({ processed: count });
    }

    if (action === "process_all") {
      const escalations = await processEscalationTasks(supabase);
      const outbox = await processNotificationOutbox(supabase);
      return jsonResponse({
        escalations_processed: escalations,
        outbox_processed: outbox,
      });
    }

    // Start escalation for an alarm
    if (action === "start_escalation") {
      const alarmId = body.alarm_id as string;
      const policyId = body.policy_id as string;

      if (!alarmId || !policyId) {
        return jsonResponse({ error: "alarm_id and policy_id required" }, 400);
      }

      // Verify alarm exists and is active
      const { data: alarm } = await supabase
        .from("alarms")
        .select("id, project_id, status")
        .eq("id", alarmId)
        .single();

      if (!alarm) return jsonResponse({ error: "Alarm not found" }, 404);
      if (alarm.status === "cleared") return jsonResponse({ error: "Alarm already cleared" }, 400);

      // Get first stage
      const { data: firstStage } = await supabase
        .from("escalation_stages")
        .select("*")
        .eq("policy_id", policyId)
        .eq("stage_number", 1)
        .single();

      if (!firstStage) return jsonResponse({ error: "No stages in policy" }, 400);

      // Schedule the first escalation task
      const scheduledAt = new Date(Date.now() + firstStage.delay_minutes * 60000).toISOString();
      const { data: task } = await supabase
        .from("escalation_tasks")
        .insert({
          alarm_id: alarmId,
          policy_id: policyId,
          stage_id: firstStage.id,
          scheduled_at: scheduledAt,
          status: "pending",
        })
        .select("id")
        .single();

      // Update alarm with escalation info
      await supabase
        .from("alarms")
        .update({
          escalation_policy_id: policyId,
          escalation_stage: 0,
        })
        .eq("id", alarmId);

      return jsonResponse({
        started: true,
        task_id: task?.id,
        first_stage_at: scheduledAt,
      });
    }

    return jsonResponse({ error: `Unknown action: ${action}` }, 400);
  } catch (err) {
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});
