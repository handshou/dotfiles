import assert from "node:assert/strict";
import test from "node:test";
import { evaluateMcpReadOnlyPolicy } from "./index.ts";

test("Supabase table listing and Vercel deployment listing are allowed", () => {
  assert.equal(evaluateMcpReadOnlyPolicy("mcp__supabase__list_tables"), undefined);
  assert.equal(evaluateMcpReadOnlyPolicy("mcp__vercel__list_deployments"), undefined);
});

test("Supabase migrations are blocked", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("mcp__supabase__apply_migration") ?? "",
    /Supabase write access is blocked/,
  );
});

test("Vercel deployments are blocked", () => {
  assert.match(
    evaluateMcpReadOnlyPolicy("mcp__vercel__deploy_to_vercel") ?? "",
    /Vercel write access is blocked/,
  );
});

test("unknown protected tools fail closed, including names sharing a read-tool prefix", () => {
  assert.match(evaluateMcpReadOnlyPolicy("mcp__supabase__unknown_tool") ?? "", /Supabase write access is blocked/);
  assert.match(evaluateMcpReadOnlyPolicy("mcp__vercel__unknown_tool") ?? "", /Vercel write access is blocked/);
  assert.match(evaluateMcpReadOnlyPolicy("mcp__supabase__list_tables__write") ?? "", /Supabase write access is blocked/);
});

test("Linear, discovery, and similarly named server namespaces are unaffected", () => {
  assert.equal(evaluateMcpReadOnlyPolicy("mcp__linear__create_issue"), undefined);
  assert.equal(evaluateMcpReadOnlyPolicy("tool_search"), undefined);
  assert.equal(evaluateMcpReadOnlyPolicy("mcp__supabase_other__execute_sql"), undefined);
});
