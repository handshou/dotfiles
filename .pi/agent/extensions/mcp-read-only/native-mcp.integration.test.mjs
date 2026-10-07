import assert from "node:assert/strict";
import { mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import path from "node:path";
import test from "node:test";
import { createAgentSession, createCodemodeExtension, DefaultResourceLoader, SessionManager, SettingsManager } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
import registerMcpReadOnlyPermissionGate from "./index.ts";

test("native MCP calls from codemode pass through the read-only gate", async () => {
  const directory = await mkdtemp(path.join(tmpdir(), "pi-mcp-read-only-"));
  const executed = [];
  const observed = [];
  const settingsManager = SettingsManager.inMemory({ defaultTools: ["codemode"] });
  const resourceLoader = new DefaultResourceLoader({
    cwd: directory,
    agentDir: directory,
    settingsManager,
    noExtensions: true,
    noSkills: true,
    noPromptTemplates: true,
    noThemes: true,
    noContextFiles: true,
    extensionFactories: [
      registerMcpReadOnlyPermissionGate,
      createCodemodeExtension({ models: false }),
      (pi) => {
        pi.on("tool_call", (event) => {
          observed.push(event);
        });
        for (const name of [
          "mcp__supabase__list_projects",
          "mcp__supabase__apply_migration",
          "mcp__vercel__get_project",
          "mcp__vercel__deploy_to_vercel",
          "mcp__vercel__new_unclassified_tool",
          "mcp__linear__create_issue",
        ]) {
          pi.registerTool({
            name,
            label: name,
            description: "Local test fixture",
            parameters: Type.Object({}),
            exposure: "deferred",
            execute: async () => {
              executed.push(name);
              return { content: [{ type: "text", text: "fixture succeeded" }], details: undefined };
            },
          });
        }
      },
    ],
  });
  let session;
  try {
    await resourceLoader.reload();
    assert.deepEqual(resourceLoader.getExtensions().errors, []);
    ({ session } = await createAgentSession({
      cwd: directory,
      agentDir: directory,
      resourceLoader,
      settingsManager,
      sessionManager: SessionManager.inMemory(),
    }));
    await session.bindExtensions({});
    session.agent.state.messages.push({
      role: "assistant",
      content: [{ type: "toolCall", id: "read-only-fixture", name: "codemode", arguments: {} }],
      api: "openai-responses",
      provider: "openai",
      model: "fixture",
      usage: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, totalTokens: 0, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
      stopReason: "toolUse",
      timestamp: Date.now(),
    });
    const codemode = session.agent.state.tools.find((tool) => tool.name === "codemode");
    assert.ok(codemode);
    const result = await codemode.execute("read-only-fixture", {
      code: `
        const outcomes = await Promise.allSettled([
          tools.mcp__supabase__list_projects({}),
          tools.mcp__supabase__apply_migration({}),
          tools.mcp__vercel__get_project({}),
          tools.mcp__vercel__deploy_to_vercel({}),
          tools.mcp__vercel__new_unclassified_tool({}),
          tools.mcp__linear__create_issue({}),
        ]);
        return outcomes.map((outcome) => ({
          status: outcome.status,
          reason: outcome.status === "rejected" ? String(outcome.reason) : undefined,
        }));
      `,
    });
    const output = result.content.filter((block) => block.type === "text").map((block) => block.text).join("\n");
    assert.match(output, /Script completed/);
    assert.match(output, /Supabase write access is blocked/);
    assert.match(output, /Vercel write access is blocked/);
    assert.equal((output.match(/"status":"rejected"/g) ?? []).length, 3);
    assert.deepEqual(executed.sort(), [
      "mcp__linear__create_issue",
      "mcp__supabase__list_projects",
      "mcp__vercel__get_project",
    ]);
    assert.ok(observed.length > 0);
    assert.ok(observed.every((event) => event.parentToolCallId === "read-only-fixture"));
  } finally {
    session?.dispose();
    await rm(directory, { recursive: true, force: true });
  }
});
