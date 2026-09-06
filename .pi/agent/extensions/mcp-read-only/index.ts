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

interface McpProxyInput {
  readonly server?: unknown;
  readonly tool?: unknown;
}

interface ProtectedMcpTool {
  readonly server: "supabase" | "vercel";
  readonly tool: string;
}

/** Returns a denial reason when an MCP call could write to protected Supabase or Vercel resources. */
export function evaluateMcpReadOnlyPolicy(toolName: string, input: unknown): string | undefined {
  const protectedTool = resolveProtectedMcpTool(toolName, input);
  if (!protectedTool) return undefined;

  const policy = PROTECTED_SERVER_POLICIES.get(protectedTool.server);
  if (policy?.allowedTools.has(protectedTool.tool)) return undefined;

  return `MCP read-only policy: ${policy?.label ?? protectedTool.server} write access is blocked; tool ${protectedTool.tool} is not on the read-only allowlist.`;
}

/** Blocks MCP write calls while preserving discovery and explicitly allowlisted read operations. */
export default function registerMcpReadOnlyPermissionGate(pi: ExtensionAPI): void {
  pi.on("tool_call", (toolCallEvent) => {
    const denialReason = evaluateMcpReadOnlyPolicy(toolCallEvent.toolName, toolCallEvent.input);
    if (!denialReason) return;

    return { block: true, reason: denialReason, terminate: true };
  });
}

function resolveProtectedMcpTool(toolName: string, input: unknown): ProtectedMcpTool | undefined {
  if (toolName !== "mcp") return parsePrefixedProtectedTool(toolName);
  if (!isMcpProxyInput(input) || typeof input.tool !== "string") return undefined;

  if (input.server === "supabase" || input.server === "vercel") {
    return {
      server: input.server,
      tool: removeServerPrefix(input.tool, input.server),
    };
  }

  return parsePrefixedProtectedTool(input.tool);
}

function parsePrefixedProtectedTool(toolName: string): ProtectedMcpTool | undefined {
  if (toolName.startsWith("supabase_")) {
    return { server: "supabase", tool: toolName.slice("supabase_".length) };
  }
  if (toolName.startsWith("vercel_")) {
    return { server: "vercel", tool: toolName.slice("vercel_".length) };
  }
  return undefined;
}

function removeServerPrefix(toolName: string, server: "supabase" | "vercel"): string {
  const prefix = `${server}_`;
  return toolName.startsWith(prefix) ? toolName.slice(prefix.length) : toolName;
}

function isMcpProxyInput(input: unknown): input is McpProxyInput {
  return typeof input === "object" && input !== null && !Array.isArray(input);
}
