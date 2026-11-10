import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient, SupabaseClient } from "https://esm.sh/@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, content-type",
};

const MAX_EXECUTION_DEPTH = 5;
const COMMAND_THROTTLE_MS = 5000;

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

interface RuleEvent {
  event_type: string;
  device_id?: string;
  project_id: string;
  organization_id: string;
  sensor_key?: string;
  value?: number | string | boolean;
  payload?: Record<string, unknown>;
  correlation_id?: string;
  causation_id?: string;
  depth?: number;
  idempotency_key?: string;
  dry_run?: boolean;
  // For targeting a specific rule (dry-run / manual trigger)
  automation_id?: string;
}

interface GraphNode {
  id: string;
  type: string;
  config: Record<string, unknown>;
  label?: string;
}

interface GraphEdge {
  id: string;
  source_node_id: string;
  source_port: string;
  target_node_id: string;
  target_port: string;
}

interface RuleGraph {
  schema_version: number;
  nodes: GraphNode[];
  edges: GraphEdge[];
}

interface NodeResult {
  node_id: string;
  node_type: string;
  status: "evaluated" | "skipped" | "failed";
  output: unknown;
  error?: string;
  evaluated_at: string;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function generateUUID(): string {
  return crypto.randomUUID();
}

function topologicalSort(nodes: GraphNode[], edges: GraphEdge[]): GraphNode[] {
  const adj = new Map<string, string[]>();
  const inDeg = new Map<string, number>();
  for (const n of nodes) {
    adj.set(n.id, []);
    inDeg.set(n.id, 0);
  }
  for (const e of edges) {
    adj.get(e.source_node_id)?.push(e.target_node_id);
    inDeg.set(e.target_node_id, (inDeg.get(e.target_node_id) ?? 0) + 1);
  }
  const queue: string[] = [];
  for (const [id, deg] of inDeg) {
    if (deg === 0) queue.push(id);
  }
  const sorted: string[] = [];
  while (queue.length > 0) {
    const cur = queue.shift()!;
    sorted.push(cur);
    for (const neighbor of adj.get(cur) ?? []) {
      const nd = (inDeg.get(neighbor) ?? 1) - 1;
      inDeg.set(neighbor, nd);
      if (nd === 0) queue.push(neighbor);
    }
  }
  const nodeMap = new Map(nodes.map((n) => [n.id, n]));
  return sorted.map((id) => nodeMap.get(id)!).filter(Boolean);
}

// ---------------------------------------------------------------------------
// Trigger evaluation
// ---------------------------------------------------------------------------

function evaluateTrigger(
  node: GraphNode,
  event: RuleEvent
): { fired: boolean; output: unknown } {
  const cfg = node.config;
  const t = node.type;

  // Device matching (most triggers need it)
  const cfgDevice = cfg.device_id as string | undefined;
  if (cfgDevice && cfgDevice !== event.device_id) {
    return { fired: false, output: null };
  }

  switch (t) {
    case "telemetryReceived":
      return { fired: event.event_type === "telemetry_received", output: event.value };

    case "sensorValueChanged": {
      if (event.event_type !== "sensor_value_changed" && event.event_type !== "telemetry_received")
        return { fired: false, output: null };
      const cfgKey = cfg.sensor_key as string | undefined;
      if (cfgKey && cfgKey !== event.sensor_key) return { fired: false, output: null };
      return { fired: true, output: event.value };
    }

    case "sensorAboveThreshold": {
      if (!["sensor_value_changed", "telemetry_received", "sensor_above_threshold"].includes(event.event_type))
        return { fired: false, output: null };
      const cfgKey = cfg.sensor_key as string | undefined;
      if (cfgKey && cfgKey !== event.sensor_key) return { fired: false, output: null };
      const threshold = cfg.threshold as number;
      const val = typeof event.value === "number" ? event.value : NaN;
      return { fired: val > threshold, output: val };
    }

    case "sensorBelowThreshold": {
      if (!["sensor_value_changed", "telemetry_received", "sensor_below_threshold"].includes(event.event_type))
        return { fired: false, output: null };
      const cfgKey = cfg.sensor_key as string | undefined;
      if (cfgKey && cfgKey !== event.sensor_key) return { fired: false, output: null };
      const threshold = cfg.threshold as number;
      const val = typeof event.value === "number" ? event.value : NaN;
      return { fired: val < threshold, output: val };
    }

    case "deviceOnlineTrigger":
      return { fired: event.event_type === "device_online", output: true };

    case "deviceOfflineTrigger":
      return { fired: event.event_type === "device_offline", output: false };

    case "deviceStatusChanged":
      return {
        fired: ["device_online", "device_offline", "device_status_changed"].includes(event.event_type),
        output: event.payload,
      };

    case "twinReportedChanged":
      return { fired: event.event_type === "twin_reported_changed", output: event.payload };

    case "twinDesiredChanged":
      return { fired: event.event_type === "twin_desired_changed", output: event.payload };

    case "manualTrigger":
      return { fired: event.event_type === "manual_trigger", output: event.payload ?? {} };

    case "scheduledTrigger":
      return { fired: event.event_type === "scheduled_trigger", output: event.payload ?? {} };

    default:
      return { fired: false, output: null };
  }
}

// ---------------------------------------------------------------------------
// Condition evaluation
// ---------------------------------------------------------------------------

function evaluateCondition(
  node: GraphNode,
  inputValue: unknown,
  nodeOutputs: Map<string, unknown>,
  edges: GraphEdge[],
  supabase: SupabaseClient
): { result: boolean; output: unknown } {
  const cfg = node.config;
  const t = node.type;

  // Resolve the effective value — for comparison nodes the input is the
  // value flowing through the graph; the config provides the operand.
  const val = inputValue;

  switch (t) {
    case "equalTo":
      return { result: val == cfg.value, output: val == cfg.value };

    case "notEqualTo":
      return { result: val != cfg.value, output: val != cfg.value };

    case "greaterThan": {
      const numVal = Number(val);
      const threshold = Number(cfg.value);
      const r = !isNaN(numVal) && !isNaN(threshold) && numVal > threshold;
      return { result: r, output: r };
    }

    case "greaterThanOrEqual": {
      const numVal = Number(val);
      const threshold = Number(cfg.value);
      const r = !isNaN(numVal) && !isNaN(threshold) && numVal >= threshold;
      return { result: r, output: r };
    }

    case "lessThan": {
      const numVal = Number(val);
      const threshold = Number(cfg.value);
      const r = !isNaN(numVal) && !isNaN(threshold) && numVal < threshold;
      return { result: r, output: r };
    }

    case "lessThanOrEqual": {
      const numVal = Number(val);
      const threshold = Number(cfg.value);
      const r = !isNaN(numVal) && !isNaN(threshold) && numVal <= threshold;
      return { result: r, output: r };
    }

    case "betweenRange": {
      const numVal = Number(val);
      const min = Number(cfg.min_value);
      const max = Number(cfg.max_value);
      const r = !isNaN(numVal) && numVal >= min && numVal <= max;
      return { result: r, output: r };
    }

    case "booleanCheck": {
      const expected = cfg.expected === true || cfg.expected === "true";
      const actual = val === true || val === "true" || val === 1;
      return { result: actual === expected, output: actual === expected };
    }

    case "andGate": {
      // Resolve inputs from connected edges
      const inEdges = edges.filter((e) => e.target_node_id === node.id);
      const results = inEdges.map((e) => {
        const v = nodeOutputs.get(e.source_node_id);
        return v === true || v === "true" || v === 1;
      });
      const r = results.length > 0 && results.every(Boolean);
      return { result: r, output: r };
    }

    case "orGate": {
      const inEdges = edges.filter((e) => e.target_node_id === node.id);
      const results = inEdges.map((e) => {
        const v = nodeOutputs.get(e.source_node_id);
        return v === true || v === "true" || v === 1;
      });
      const r = results.some(Boolean);
      return { result: r, output: r };
    }

    case "notGate": {
      const boolVal = val === true || val === "true" || val === 1;
      return { result: !boolVal, output: !boolVal };
    }

    case "deviceOnlineCheck": {
      // This will be resolved asynchronously in the main loop
      // Return a placeholder; the main loop handles async conditions
      return { result: false, output: false };
    }

    case "twinDesiredVsReported": {
      // Placeholder — resolved asynchronously in the main loop
      return { result: false, output: false };
    }

    default:
      return { result: false, output: false };
  }
}

// ---------------------------------------------------------------------------
// Async condition evaluation (requires DB lookups)
// ---------------------------------------------------------------------------

async function evaluateAsyncCondition(
  node: GraphNode,
  supabase: SupabaseClient
): Promise<{ result: boolean; output: unknown }> {
  const cfg = node.config;

  if (node.type === "deviceOnlineCheck") {
    const deviceId = cfg.device_id as string;
    if (!deviceId) return { result: false, output: false };
    const { data } = await supabase
      .from("devices")
      .select("is_online")
      .eq("id", deviceId)
      .single();
    const isOnline = data?.is_online === true;
    return { result: isOnline, output: isOnline };
  }

  if (node.type === "twinDesiredVsReported") {
    const deviceId = cfg.device_id as string;
    const attrKey = cfg.attribute_key as string;
    if (!deviceId || !attrKey) return { result: false, output: false };
    const { data } = await supabase
      .from("device_twin_state")
      .select("desired_state, reported_state")
      .eq("device_id", deviceId)
      .single();
    if (!data) return { result: false, output: false };
    const desired = data.desired_state?.[attrKey];
    const reported = data.reported_state?.[attrKey];
    const match = desired === reported;
    return { result: match, output: { desired, reported, match } };
  }

  return { result: false, output: false };
}

// ---------------------------------------------------------------------------
// Action execution
// ---------------------------------------------------------------------------

async function executeAction(
  node: GraphNode,
  event: RuleEvent,
  dryRun: boolean,
  supabase: SupabaseClient,
  correlationId: string,
  commandThrottle: Map<string, number>
): Promise<{ success: boolean; output: unknown; error?: string }> {
  const cfg = node.config;
  const now = Date.now();

  try {
    switch (node.type) {
      case "sendCommand": {
        const deviceId = cfg.device_id as string;
        const cmdType = cfg.command_type as string || "custom";
        const payload = cfg.payload as Record<string, unknown> || {};
        if (!deviceId) return { success: false, output: null, error: "Missing device_id" };

        // Per-device command throttle within same correlation
        const throttleKey = `${correlationId}:${deviceId}`;
        const lastCmd = commandThrottle.get(throttleKey) ?? 0;
        if (now - lastCmd < COMMAND_THROTTLE_MS) {
          return { success: false, output: null, error: "Command throttled (5s per device per correlation)" };
        }

        if (!dryRun) {
          const { error } = await supabase.from("device_commands").insert({
            device_id: deviceId,
            command_type: cmdType,
            payload,
            status: "pending",
            expires_at: new Date(now + 30000).toISOString(),
          });
          if (error) return { success: false, output: null, error: error.message };
          commandThrottle.set(throttleKey, now);
        }
        return { success: true, output: { device_id: deviceId, command_type: cmdType, dry_run: dryRun } };
      }

      case "setActuator": {
        const deviceId = cfg.device_id as string;
        const actuatorKey = cfg.actuator_key as string;
        const value = cfg.value;
        if (!deviceId || !actuatorKey) return { success: false, output: null, error: "Missing device_id or actuator_key" };

        const throttleKey = `${correlationId}:${deviceId}`;
        const lastCmd = commandThrottle.get(throttleKey) ?? 0;
        if (now - lastCmd < COMMAND_THROTTLE_MS) {
          return { success: false, output: null, error: "Command throttled" };
        }

        if (!dryRun) {
          const { error } = await supabase.from("device_commands").insert({
            device_id: deviceId,
            command_type: "set_actuator",
            payload: { actuator_key: actuatorKey, value },
            status: "pending",
            expires_at: new Date(now + 30000).toISOString(),
          });
          if (error) return { success: false, output: null, error: error.message };
          commandThrottle.set(throttleKey, now);
        }
        return { success: true, output: { device_id: deviceId, actuator_key: actuatorKey, value, dry_run: dryRun } };
      }

      case "updateTwinDesired": {
        const deviceId = cfg.device_id as string;
        const attrs = cfg.attributes as Record<string, unknown>;
        if (!deviceId || !attrs) return { success: false, output: null, error: "Missing device_id or attributes" };

        if (!dryRun) {
          const { data: existing } = await supabase
            .from("device_twin_state")
            .select("desired_state, desired_version")
            .eq("device_id", deviceId)
            .single();

          if (existing) {
            const merged = { ...(existing.desired_state || {}), ...attrs };
            const { error } = await supabase
              .from("device_twin_state")
              .update({
                desired_state: merged,
                desired_version: (existing.desired_version || 0) + 1,
                desired_at: new Date().toISOString(),
                sync_status: "pending",
              })
              .eq("device_id", deviceId);
            if (error) return { success: false, output: null, error: error.message };
          }
        }
        return { success: true, output: { device_id: deviceId, attributes: attrs, dry_run: dryRun } };
      }

      case "executeScene": {
        const sceneId = cfg.scene_id as string;
        if (!sceneId) return { success: false, output: null, error: "Missing scene_id" };

        if (!dryRun) {
          const { data: actions } = await supabase
            .from("scene_actions")
            .select("*")
            .eq("scene_id", sceneId)
            .order("sort_order");

          for (const action of actions || []) {
            if (action.device_id) {
              await supabase.from("device_commands").insert({
                device_id: action.device_id,
                command_type: action.action_type || "set_state",
                payload: action.target_state || {},
                status: "pending",
                expires_at: new Date(now + 30000).toISOString(),
              });
            }
          }
          await supabase
            .from("scenes")
            .update({ last_activated_at: new Date().toISOString() })
            .eq("id", sceneId);
        }
        return { success: true, output: { scene_id: sceneId, dry_run: dryRun } };
      }

      case "recordEvent": {
        const eventName = cfg.event_name as string || "rule_event";
        const eventMsg = cfg.message as string || "";

        if (!dryRun) {
          await supabase.from("rule_events").insert({
            event_type: "automation_event",
            project_id: event.project_id,
            organization_id: event.organization_id,
            device_id: event.device_id || null,
            payload: { event_name: eventName, message: eventMsg, source_correlation: correlationId },
            correlation_id: correlationId,
            depth: (event.depth ?? 0),
            status: "completed",
            processed_at: new Date().toISOString(),
          });
        }
        return { success: true, output: { event_name: eventName, dry_run: dryRun } };
      }

      case "logResult": {
        const message = cfg.message as string || "Rule execution logged";
        return { success: true, output: { message, dry_run: dryRun } };
      }

      case "stopFlow": {
        return { success: true, output: { stopped: true } };
      }

      // ----- Phase 9: Alarm action nodes -----

      case "raiseAlarm": {
        const alarmKey = cfg.alarm_key as string;
        const severity = cfg.severity as string || "warning";
        const title = cfg.title as string || "Alarm";
        const message = cfg.message as string || "";
        const category = cfg.category as string || "general";
        if (!alarmKey) return { success: false, output: null, error: "Missing alarm_key" };

        if (!dryRun) {
          // Upsert: if alarm with same key exists and is active/acknowledged, increment occurrence_count
          const { data: existing } = await supabase
            .from("alarms")
            .select("id, status, occurrence_count")
            .eq("alarm_key", alarmKey)
            .eq("project_id", event.project_id)
            .in("status", ["active", "acknowledged"])
            .limit(1);

          if (existing && existing.length > 0) {
            const alarm = existing[0];
            await supabase
              .from("alarms")
              .update({
                occurrence_count: (alarm.occurrence_count || 1) + 1,
                last_occurred_at: new Date().toISOString(),
                severity,
                condition_value: event.value ?? null,
              })
              .eq("id", alarm.id);

            return { success: true, output: { alarm_id: alarm.id, alarm_key: alarmKey, deduplicated: true, dry_run: false } };
          }

          // Create new alarm
          const { data: newAlarm, error: insertErr } = await supabase
            .from("alarms")
            .insert({
              alarm_key: alarmKey,
              project_id: event.project_id,
              device_id: event.device_id || null,
              organization_id: event.organization_id,
              severity,
              status: "active",
              source: "rule_action",
              title,
              message,
              category,
              condition_value: event.value ?? null,
              data: { correlation_id: correlationId, event_type: event.event_type },
            })
            .select("id")
            .single();

          if (insertErr) return { success: false, output: null, error: insertErr.message };

          // Record creation activity
          if (newAlarm) {
            await supabase.from("alarm_activity").insert({
              alarm_id: newAlarm.id,
              activity_type: "created",
              data: { source: "rule_action", correlation_id: correlationId },
            });
          }

          return { success: true, output: { alarm_id: newAlarm?.id, alarm_key: alarmKey, deduplicated: false, dry_run: false } };
        }
        return { success: true, output: { alarm_key: alarmKey, severity, title, dry_run: true } };
      }

      case "updateAlarmSeverity": {
        const alarmKey = cfg.alarm_key as string;
        const newSeverity = cfg.severity as string || "warning";
        if (!alarmKey) return { success: false, output: null, error: "Missing alarm_key" };

        if (!dryRun) {
          const { data: existing } = await supabase
            .from("alarms")
            .select("id, severity")
            .eq("alarm_key", alarmKey)
            .eq("project_id", event.project_id)
            .in("status", ["active", "acknowledged"])
            .limit(1);

          if (!existing || existing.length === 0) {
            return { success: false, output: null, error: `No active alarm found for key: ${alarmKey}` };
          }

          const alarm = existing[0];
          const previousSeverity = alarm.severity;

          await supabase
            .from("alarms")
            .update({ severity: newSeverity })
            .eq("id", alarm.id);

          await supabase.from("alarm_activity").insert({
            alarm_id: alarm.id,
            activity_type: "severity_changed",
            previous_severity: previousSeverity,
            new_severity: newSeverity,
            data: { correlation_id: correlationId },
          });

          return { success: true, output: { alarm_id: alarm.id, previous_severity: previousSeverity, new_severity: newSeverity, dry_run: false } };
        }
        return { success: true, output: { alarm_key: alarmKey, severity: newSeverity, dry_run: true } };
      }

      case "clearAlarm": {
        const alarmKey = cfg.alarm_key as string;
        const reason = cfg.reason as string || "Cleared by rule action";
        if (!alarmKey) return { success: false, output: null, error: "Missing alarm_key" };

        if (!dryRun) {
          const { data: existing } = await supabase
            .from("alarms")
            .select("id, status")
            .eq("alarm_key", alarmKey)
            .eq("project_id", event.project_id)
            .in("status", ["active", "acknowledged"])
            .limit(1);

          if (!existing || existing.length === 0) {
            return { success: true, output: { alarm_key: alarmKey, already_cleared: true, dry_run: false } };
          }

          const alarm = existing[0];
          await supabase
            .from("alarms")
            .update({
              status: "cleared",
              cleared_at: new Date().toISOString(),
              cleared_reason: reason,
            })
            .eq("id", alarm.id);

          await supabase.from("alarm_activity").insert({
            alarm_id: alarm.id,
            activity_type: "cleared",
            comment: reason,
            data: { source: "rule_action", correlation_id: correlationId },
          });

          // Cancel pending escalation tasks
          await supabase
            .from("escalation_tasks")
            .update({ status: "cancelled" })
            .eq("alarm_id", alarm.id)
            .eq("status", "pending");

          return { success: true, output: { alarm_id: alarm.id, alarm_key: alarmKey, cleared: true, dry_run: false } };
        }
        return { success: true, output: { alarm_key: alarmKey, reason, dry_run: true } };
      }

      case "addAlarmComment": {
        const alarmKey = cfg.alarm_key as string;
        const comment = cfg.comment as string || "";
        if (!alarmKey) return { success: false, output: null, error: "Missing alarm_key" };
        if (!comment) return { success: false, output: null, error: "Missing comment" };

        if (!dryRun) {
          const { data: existing } = await supabase
            .from("alarms")
            .select("id")
            .eq("alarm_key", alarmKey)
            .eq("project_id", event.project_id)
            .limit(1);

          if (!existing || existing.length === 0) {
            return { success: false, output: null, error: `No alarm found for key: ${alarmKey}` };
          }

          await supabase.from("alarm_activity").insert({
            alarm_id: existing[0].id,
            activity_type: "comment_added",
            comment,
            data: { source: "rule_action", correlation_id: correlationId },
          });

          return { success: true, output: { alarm_id: existing[0].id, comment_added: true, dry_run: false } };
        }
        return { success: true, output: { alarm_key: alarmKey, comment, dry_run: true } };
      }

      default:
        return { success: false, output: null, error: `Unknown action type: ${node.type}` };
    }
  } catch (err) {
    return { success: false, output: null, error: String(err) };
  }
}

// ---------------------------------------------------------------------------
// Graph rule evaluator
// ---------------------------------------------------------------------------

async function evaluateGraphRule(
  automation: Record<string, unknown>,
  graph: RuleGraph,
  event: RuleEvent,
  dryRun: boolean,
  correlationId: string,
  depth: number,
  ruleVersionId: string | null,
  supabase: SupabaseClient
): Promise<{ executed: boolean; nodeResults: NodeResult[]; error?: string }> {
  const nodeResults: NodeResult[] = [];
  const nodeOutputs = new Map<string, unknown>();
  const commandThrottle = new Map<string, number>();
  let flowStopped = false;

  const sorted = topologicalSort(graph.nodes, graph.edges);

  // Build a lookup of which port an edge enters a node on
  const incomingEdges = new Map<string, GraphEdge[]>();
  for (const e of graph.edges) {
    const arr = incomingEdges.get(e.target_node_id) ?? [];
    arr.push(e);
    incomingEdges.set(e.target_node_id, arr);
  }

  const outgoingEdges = new Map<string, GraphEdge[]>();
  for (const e of graph.edges) {
    const arr = outgoingEdges.get(e.source_node_id) ?? [];
    arr.push(e);
    outgoingEdges.set(e.source_node_id, arr);
  }

  // Set of node IDs whose branch was NOT taken (skipped)
  const skippedBranches = new Set<string>();

  for (const node of sorted) {
    if (flowStopped) {
      nodeResults.push({
        node_id: node.id,
        node_type: node.type,
        status: "skipped",
        output: null,
        evaluated_at: new Date().toISOString(),
      });
      continue;
    }

    // Check if this node is on a skipped branch
    const myIncoming = incomingEdges.get(node.id) ?? [];
    if (myIncoming.length > 0) {
      const allSkipped = myIncoming.every((e) => skippedBranches.has(`${e.source_node_id}:${e.source_port}`));
      if (allSkipped) {
        nodeResults.push({
          node_id: node.id,
          node_type: node.type,
          status: "skipped",
          output: null,
          evaluated_at: new Date().toISOString(),
        });
        // Propagate skip to downstream
        for (const oe of outgoingEdges.get(node.id) ?? []) {
          skippedBranches.add(`${node.id}:${oe.source_port}`);
        }
        continue;
      }
    }

    // Resolve input value from upstream nodes
    let inputValue: unknown = null;
    if (myIncoming.length > 0) {
      // Take the first non-null upstream output
      for (const ie of myIncoming) {
        const upstreamOut = nodeOutputs.get(ie.source_node_id);
        if (upstreamOut !== null && upstreamOut !== undefined) {
          inputValue = upstreamOut;
          break;
        }
      }
    }

    try {
      const category = getNodeCategory(node.type);

      if (category === "trigger") {
        const { fired, output } = evaluateTrigger(node, event);
        nodeOutputs.set(node.id, output);
        nodeResults.push({
          node_id: node.id,
          node_type: node.type,
          status: fired ? "evaluated" : "skipped",
          output,
          evaluated_at: new Date().toISOString(),
        });
        if (!fired) {
          return { executed: false, nodeResults };
        }
      } else if (category === "condition") {
        let condResult: { result: boolean; output: unknown };

        if (node.type === "deviceOnlineCheck" || node.type === "twinDesiredVsReported") {
          condResult = await evaluateAsyncCondition(node, supabase);
        } else {
          condResult = evaluateCondition(node, inputValue, nodeOutputs, graph.edges, supabase);
        }

        nodeOutputs.set(node.id, condResult.output);
        nodeResults.push({
          node_id: node.id,
          node_type: node.type,
          status: "evaluated",
          output: condResult.output,
          evaluated_at: new Date().toISOString(),
        });
      } else if (category === "action") {
        const actionResult = await executeAction(
          node, event, dryRun, supabase, correlationId, commandThrottle
        );
        nodeOutputs.set(node.id, actionResult.output);
        nodeResults.push({
          node_id: node.id,
          node_type: node.type,
          status: actionResult.success ? "evaluated" : "failed",
          output: actionResult.output,
          error: actionResult.error,
          evaluated_at: new Date().toISOString(),
        });

        if (node.type === "stopFlow") {
          flowStopped = true;
        }
      } else if (category === "flow") {
        if (node.type === "conditionalBranch") {
          const boolInput = inputValue === true || inputValue === "true" || inputValue === 1;
          nodeOutputs.set(node.id, boolInput);

          // Mark the NOT-taken branch as skipped
          const myOutEdges = outgoingEdges.get(node.id) ?? [];
          for (const oe of myOutEdges) {
            if (boolInput && oe.source_port === "false") {
              skippedBranches.add(`${node.id}:false`);
            } else if (!boolInput && oe.source_port === "true") {
              skippedBranches.add(`${node.id}:true`);
            }
          }

          nodeResults.push({
            node_id: node.id,
            node_type: node.type,
            status: "evaluated",
            output: boolInput,
            evaluated_at: new Date().toISOString(),
          });
        } else if (node.type === "delay") {
          const durationMs = Number(node.config.duration_ms) || 1000;
          // In an Edge Function we cannot truly delay durably.
          // We simulate the delay for short durations (up to 10s).
          // Longer delays are logged but not awaited.
          if (durationMs <= 10000) {
            await new Promise((r) => setTimeout(r, durationMs));
          }
          nodeOutputs.set(node.id, inputValue);
          nodeResults.push({
            node_id: node.id,
            node_type: node.type,
            status: "evaluated",
            output: { delayed_ms: durationMs, simulated: durationMs > 10000 },
            evaluated_at: new Date().toISOString(),
          });
        } else if (node.type === "merge") {
          // Merge takes the first non-null upstream value
          nodeOutputs.set(node.id, inputValue);
          nodeResults.push({
            node_id: node.id,
            node_type: node.type,
            status: "evaluated",
            output: inputValue,
            evaluated_at: new Date().toISOString(),
          });
        } else if (node.type === "terminate") {
          flowStopped = true;
          nodeResults.push({
            node_id: node.id,
            node_type: node.type,
            status: "evaluated",
            output: { terminated: true },
            evaluated_at: new Date().toISOString(),
          });
        }
      }
    } catch (err) {
      nodeResults.push({
        node_id: node.id,
        node_type: node.type,
        status: "failed",
        output: null,
        error: String(err),
        evaluated_at: new Date().toISOString(),
      });
    }
  }

  return { executed: true, nodeResults };
}

function getNodeCategory(type: string): string {
  const triggers = [
    "telemetryReceived", "sensorValueChanged", "sensorAboveThreshold",
    "sensorBelowThreshold", "deviceOnlineTrigger", "deviceOfflineTrigger",
    "deviceStatusChanged", "twinReportedChanged", "twinDesiredChanged",
    "manualTrigger", "scheduledTrigger",
  ];
  const conditions = [
    "equalTo", "notEqualTo", "greaterThan", "greaterThanOrEqual",
    "lessThan", "lessThanOrEqual", "betweenRange", "booleanCheck",
    "andGate", "orGate", "notGate", "deviceOnlineCheck", "twinDesiredVsReported",
  ];
  const actions = [
    "sendCommand", "setActuator", "updateTwinDesired", "executeScene",
    "recordEvent", "logResult", "stopFlow",
    "raiseAlarm", "updateAlarmSeverity", "clearAlarm", "addAlarmComment",
  ];
  if (triggers.includes(type)) return "trigger";
  if (conditions.includes(type)) return "condition";
  if (actions.includes(type)) return "action";
  return "flow";
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

    const body = await req.json();

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!
    );

    // -----------------------------------------------------------------------
    // Determine request mode: legacy sensor event or new rule event
    // -----------------------------------------------------------------------

    const isNewRuleEvent = body.event_type !== undefined;

    if (!isNewRuleEvent) {
      // =====================================================================
      // LEGACY PATH — backward-compatible sensor_threshold flow
      // =====================================================================
      const { device_id, sensor_key, value } = body;

      if (!device_id || typeof device_id !== "string") {
        return jsonResponse({ error: "device_id (string) required" }, 400);
      }
      if (!sensor_key || typeof sensor_key !== "string") {
        return jsonResponse({ error: "sensor_key (string) required" }, 400);
      }
      if (typeof value !== "number" || !isFinite(value)) {
        return jsonResponse({ error: "value must be a finite number" }, 400);
      }

      const { data: device } = await supabase
        .from("devices")
        .select("id, project_id")
        .eq("id", device_id)
        .single();

      if (!device) {
        return jsonResponse({ error: "Device not found" }, 404);
      }

      // Legacy trigger-based automations (no rule_graph)
      const { data: triggers } = await supabase
        .from("automation_triggers")
        .select("*, automations!inner(*)")
        .eq("trigger_type", "sensor_threshold")
        .eq("automations.project_id", device.project_id)
        .eq("automations.is_enabled", true);

      const executedAutomations: string[] = [];

      for (const trigger of triggers || []) {
        const automation = trigger.automations;

        // Skip graph-based rules in legacy path
        if (automation.rule_graph) continue;

        const config = trigger.config;
        if (config.sensor_key !== sensor_key) continue;
        if (config.device_id && config.device_id !== device_id) continue;

        let shouldFire = false;
        const op = config.operator;
        const threshold = config.threshold;

        if (op === "gt" && value > threshold) shouldFire = true;
        if (op === "lt" && value < threshold) shouldFire = true;
        if (op === "eq" && value === threshold) shouldFire = true;
        if (op === "gte" && value >= threshold) shouldFire = true;
        if (op === "lte" && value <= threshold) shouldFire = true;
        if (op === "between" && value >= config.low && value <= config.high) shouldFire = true;

        if (!shouldFire) continue;

        const cooldownSec = automation.cooldown_seconds ?? 60;
        const { data: recentExec } = await supabase
          .from("automation_executions")
          .select("id")
          .eq("automation_id", automation.id)
          .gte("started_at", new Date(Date.now() - cooldownSec * 1000).toISOString())
          .limit(1);
        if (recentExec && recentExec.length > 0) continue;

        const maxPerHour = automation.max_executions_per_hour ?? 60;
        const { count: hourlyCount } = await supabase
          .from("automation_executions")
          .select("id", { count: "exact", head: true })
          .eq("automation_id", automation.id)
          .gte("started_at", new Date(Date.now() - 3600000).toISOString());
        if (hourlyCount !== null && hourlyCount >= maxPerHour) continue;

        const { data: actions } = await supabase
          .from("automation_actions")
          .select("*")
          .eq("automation_id", automation.id)
          .order("sort_order");

        const actionsExecuted = [];
        for (const action of actions || []) {
          try {
            if (action.action_type === "device_command" && action.config?.device_id) {
              await supabase.from("device_commands").insert({
                device_id: action.config.device_id,
                command_type: action.config.command_type || "custom",
                payload: action.config.payload || {},
                status: "pending",
                expires_at: new Date(Date.now() + 30000).toISOString(),
              });
            } else if (action.action_type === "notification" && action.config?.message) {
              await supabase.from("notifications").insert({
                user_id: null,
                project_id: automation.project_id,
                title: action.config.title || "Automation Alert",
                body: action.config.message,
                category: "automation",
                severity: action.config.severity || "info",
              });
            }
            actionsExecuted.push({
              action_id: action.id,
              action_type: action.action_type,
              status: "completed",
              executed_at: new Date().toISOString(),
            });
          } catch (actionErr) {
            actionsExecuted.push({
              action_id: action.id,
              action_type: action.action_type,
              status: "failed",
              error: String(actionErr),
              executed_at: new Date().toISOString(),
            });
          }
        }

        const startedAt = new Date().toISOString();
        await supabase.from("automation_executions").insert({
          automation_id: automation.id,
          trigger_id: trigger.id,
          trigger_data: { device_id, sensor_key, value },
          status: "completed",
          started_at: startedAt,
          completed_at: new Date().toISOString(),
          actions_executed: actionsExecuted,
        });

        await supabase
          .from("automations")
          .update({
            execution_count: automation.execution_count + 1,
            last_executed_at: startedAt,
          })
          .eq("id", automation.id);

        executedAutomations.push(automation.id);
      }

      // Also run graph-based rules for this telemetry event
      const graphEvent: RuleEvent = {
        event_type: "telemetry_received",
        device_id,
        project_id: device.project_id,
        organization_id: "",
        sensor_key,
        value,
        correlation_id: generateUUID(),
        depth: 0,
        dry_run: false,
      };

      // Resolve organization_id
      const { data: proj } = await supabase
        .from("projects")
        .select("organization_id")
        .eq("id", device.project_id)
        .single();
      if (proj) graphEvent.organization_id = proj.organization_id;

      const graphExecs = await processGraphRules(graphEvent, supabase);

      return jsonResponse({
        processed: true,
        legacy_executions: executedAutomations.length,
        graph_executions: graphExecs,
      });
    }

    // =====================================================================
    // NEW RULE EVENT PATH — graph-based evaluation
    // =====================================================================

    const event: RuleEvent = {
      event_type: body.event_type,
      device_id: body.device_id,
      project_id: body.project_id,
      organization_id: body.organization_id,
      sensor_key: body.sensor_key,
      value: body.value,
      payload: body.payload || {},
      correlation_id: body.correlation_id || generateUUID(),
      causation_id: body.causation_id,
      depth: body.depth ?? 0,
      idempotency_key: body.idempotency_key,
      dry_run: body.dry_run === true,
      automation_id: body.automation_id,
    };

    if (!event.project_id) {
      return jsonResponse({ error: "project_id required" }, 400);
    }
    if (!event.organization_id) {
      return jsonResponse({ error: "organization_id required" }, 400);
    }

    // Depth check
    if ((event.depth ?? 0) > MAX_EXECUTION_DEPTH) {
      return jsonResponse({
        processed: false,
        error: `Maximum execution depth (${MAX_EXECUTION_DEPTH}) exceeded — possible loop`,
      });
    }

    // Idempotency check
    if (event.idempotency_key) {
      const { data: existing } = await supabase
        .from("rule_events")
        .select("id, status")
        .eq("idempotency_key", event.idempotency_key)
        .limit(1);
      if (existing && existing.length > 0) {
        return jsonResponse({
          processed: false,
          reason: "duplicate_event",
          existing_event_id: existing[0].id,
        });
      }
    }

    // Insert event into inbox
    const { data: insertedEvent } = await supabase
      .from("rule_events")
      .insert({
        event_type: event.event_type,
        device_id: event.device_id || null,
        project_id: event.project_id,
        organization_id: event.organization_id,
        payload: {
          sensor_key: event.sensor_key,
          value: event.value,
          ...(event.payload || {}),
        },
        idempotency_key: event.idempotency_key || null,
        correlation_id: event.correlation_id,
        causation_id: event.causation_id || null,
        depth: event.depth ?? 0,
        status: "processing",
      })
      .select("id")
      .single();

    const eventId = insertedEvent?.id;

    const graphExecs = await processGraphRules(event, supabase);

    // Mark event as completed
    if (eventId) {
      await supabase
        .from("rule_events")
        .update({ status: "completed", processed_at: new Date().toISOString() })
        .eq("id", eventId);
    }

    return jsonResponse({
      processed: true,
      event_id: eventId,
      graph_executions: graphExecs,
    });
  } catch (err) {
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

// ---------------------------------------------------------------------------
// Process graph-based rules
// ---------------------------------------------------------------------------

async function processGraphRules(
  event: RuleEvent,
  supabase: SupabaseClient
): Promise<number> {
  let query = supabase
    .from("automations")
    .select("*")
    .eq("project_id", event.project_id)
    .eq("is_enabled", true)
    .in("status", ["published", "enabled"])
    .not("rule_graph", "is", null);

  // If targeting a specific automation (e.g. dry-run or manual trigger)
  if (event.automation_id) {
    query = supabase
      .from("automations")
      .select("*")
      .eq("id", event.automation_id)
      .not("rule_graph", "is", null);
  }

  const { data: rules } = await query;
  if (!rules || rules.length === 0) return 0;

  const correlationId = event.correlation_id || generateUUID();
  const depth = event.depth ?? 0;
  const dryRun = event.dry_run === true;
  let execCount = 0;

  for (const rule of rules) {
    // Re-entry detection: skip if same rule + correlation is already running
    const { data: running } = await supabase
      .from("automation_executions")
      .select("id")
      .eq("automation_id", rule.id)
      .eq("correlation_id", correlationId)
      .eq("status", "running")
      .limit(1);
    if (running && running.length > 0) continue;

    // Cooldown check
    const cooldownSec = rule.cooldown_seconds ?? 60;
    if (!dryRun) {
      const { data: recentExec } = await supabase
        .from("automation_executions")
        .select("id")
        .eq("automation_id", rule.id)
        .eq("dry_run", false)
        .gte("started_at", new Date(Date.now() - cooldownSec * 1000).toISOString())
        .limit(1);
      if (recentExec && recentExec.length > 0) continue;
    }

    // Rate limit check
    const maxPerHour = rule.max_executions_per_hour ?? 60;
    if (!dryRun) {
      const { count } = await supabase
        .from("automation_executions")
        .select("id", { count: "exact", head: true })
        .eq("automation_id", rule.id)
        .eq("dry_run", false)
        .gte("started_at", new Date(Date.now() - 3600000).toISOString());
      if (count !== null && count >= maxPerHour) continue;
    }

    // Load the published version graph, or fall back to rule_graph
    let graph: RuleGraph;
    let ruleVersionId: string | null = null;

    const { data: latestVersion } = await supabase
      .from("rule_versions")
      .select("id, graph_snapshot")
      .eq("automation_id", rule.id)
      .order("version_number", { ascending: false })
      .limit(1);

    if (latestVersion && latestVersion.length > 0) {
      graph = latestVersion[0].graph_snapshot as RuleGraph;
      ruleVersionId = latestVersion[0].id;
    } else {
      graph = rule.rule_graph as RuleGraph;
    }

    if (!graph || !graph.nodes || graph.nodes.length === 0) continue;

    // Create execution record in running state
    const startedAt = new Date().toISOString();
    const { data: execRecord } = await supabase
      .from("automation_executions")
      .insert({
        automation_id: rule.id,
        trigger_data: {
          event_type: event.event_type,
          device_id: event.device_id,
          sensor_key: event.sensor_key,
          value: event.value,
          payload: event.payload,
        },
        status: "running",
        started_at: startedAt,
        correlation_id: correlationId,
        execution_depth: depth,
        node_results: [],
        rule_version_id: ruleVersionId,
        dry_run: dryRun,
      })
      .select("id")
      .single();

    try {
      const result = await evaluateGraphRule(
        rule, graph, event, dryRun, correlationId, depth, ruleVersionId, supabase
      );

      const completedAt = new Date().toISOString();
      const durationMs = new Date(completedAt).getTime() - new Date(startedAt).getTime();

      await supabase
        .from("automation_executions")
        .update({
          status: result.executed ? "completed" : "cancelled",
          completed_at: completedAt,
          duration_ms: durationMs,
          node_results: result.nodeResults,
          error_message: result.error || null,
        })
        .eq("id", execRecord?.id);

      if (result.executed && !dryRun) {
        await supabase
          .from("automations")
          .update({
            execution_count: (rule.execution_count || 0) + 1,
            last_executed_at: startedAt,
          })
          .eq("id", rule.id);
      }

      if (result.executed) execCount++;
    } catch (err) {
      await supabase
        .from("automation_executions")
        .update({
          status: "failed",
          completed_at: new Date().toISOString(),
          error_message: String(err),
        })
        .eq("id", execRecord?.id);
    }
  }

  return execCount;
}
