import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SUPABASE_READ_ONLY_TOOLS = new Set([
  "list_tables",
  "list_extensions",
  "list_migrations",
  "query_logs",
  "get_advisors",
  "get_project_url",
  "get_publishable_keys",
  "generate_typescript_types",
  "list_edge_functions",
  "get_edge_function",
  "list_projects",
  "get_project",
  "list_organizations",
  "get_organization",
  "get_cost",
  "list_branches",
  "list_storage_buckets",
  "get_storage_config",
  "search_docs",
]);

const VERCEL_READ_ONLY_TOOLS = new Set([
  "search_vercel_documentation",
  "list_teams",
  "list_projects",
  "get_project",
  "list_deployments",
  "get_deployment",
  "get_deployment_build_logs",
  "get_runtime_logs",
  "get_runtime_errors",
  "get_web_analytics",
  "list_agent_run_projects",
  "list_agent_runs",
  "get_agent_run",
  "get_agent_run_trace",
  "check_domain_availability_and_price",
  "get_purchase_quote",
  "get_domain_order",
  "get_access_to_vercel_url",
  "web_fetch_vercel_url",
  "list_toolbar_threads",
  "get_toolbar_thread",
]);

const PROTECTED_SERVER_POLICIES = new Map([
  ["supabase", { label: "Supabase", allowedTools: SUPABASE_READ_ONLY_TOOLS }],
  ["vercel", { label: "Vercel", allowedTools: VERCEL_READ_ONLY_TOOLS }],
]);

interface ProtectedMcpTool {
  readonly server: "supabase" | "vercel";
  readonly tool: string;
}

/** Returns a denial reason when an MCP call could write to protected Supabase or Vercel resources. */
export function evaluateMcpReadOnlyPolicy(toolName: string): string | undefined {
  const protectedTool = parseProtectedMcpTool(toolName);
  if (!protectedTool) return undefined;

  const policy = PROTECTED_SERVER_POLICIES.get(protectedTool.server);
  if (policy?.allowedTools.has(protectedTool.tool)) return undefined;

  return `MCP read-only policy: ${policy?.label ?? protectedTool.server} write access is blocked; tool ${protectedTool.tool} is not on the read-only allowlist.`;
}

/** Blocks MCP write calls while preserving discovery and explicitly allowlisted read operations. */
export default function registerMcpReadOnlyPermissionGate(pi: ExtensionAPI): void {
  pi.on("tool_call", (toolCallEvent) => {
    const denialReason = evaluateMcpReadOnlyPolicy(toolCallEvent.toolName);
    if (!denialReason) return;

    return { block: true, reason: denialReason, terminate: true };
  });
}

function parseProtectedMcpTool(toolName: string): ProtectedMcpTool | undefined {
  if (toolName.startsWith("mcp__supabase__")) {
    return { server: "supabase", tool: toolName.slice("mcp__supabase__".length) };
  }
  if (toolName.startsWith("mcp__vercel__")) {
    return { server: "vercel", tool: toolName.slice("mcp__vercel__".length) };
  }
  return undefined;
}
