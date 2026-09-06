import assert from "node:assert/strict";
import test from "node:test";
import { evaluateMcpReadOnlyPolicy } from "./index.ts";

test("Supabase write tools are blocked through the MCP proxy", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("mcp", { tool: "supabase_apply_migration" }) ?? "",
    /Supabase write access is blocked/,
  );
});

test("Vercel deployment tools are blocked through the MCP proxy", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("mcp", { server: "vercel", tool: "deploy_to_vercel" }) ?? "",
    /Vercel write access is blocked/,
  );
});

test("known Supabase and Vercel read tools are allowed", () => {
  assert.equal(evaluateMcpReadOnlyPolicy("mcp", { tool: "supabase_list_tables" }), undefined);
  assert.equal(evaluateMcpReadOnlyPolicy("mcp", { tool: "vercel_get_project" }), undefined);
});

test("MCP discovery calls are allowed", () => {
  assert.equal(evaluateMcpReadOnlyPolicy("mcp", { search: "deployments" }), undefined);
  assert.equal(evaluateMcpReadOnlyPolicy("mcp", { server: "vercel" }), undefined);
});

test("unknown Supabase and Vercel tools fail closed", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("mcp", { tool: "supabase_new_unclassified_tool" }) ?? "",
    /Supabase write access is blocked/,
  );
  assert.match(
    evaluateMcpReadOnlyPolicy("vercel_new_unclassified_tool", {}) ?? "",
    /Vercel write access is blocked/,
  );
});

test("direct MCP write tools are blocked", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("supabase_execute_sql", {}) ?? "",
    /Supabase write access is blocked/,
  );
  assert.equal(evaluateMcpReadOnlyPolicy("vercel_get_runtime_logs", {}), undefined);
});
