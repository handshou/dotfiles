# Native MCP

Work uses the private `base/mcp.json` through a symlink; personal has its own `personal/mcp.json`. On a new machine, initialize it without overwriting existing config:

```sh
cp -n ~/.pi/base/mcp.example.json ~/.pi/base/mcp.json
```

- Restart Pi or `/reload` after changes. Use `tool_search` instead of the old `mcp` gateway; `/mcp` manages connections and sign-in.
- Validate each profile with `PI_CODING_AGENT_DIR=~/.pi/<profile> pi mcp list`. For required OAuth, use `pi mcp login <server>` with the same profile.
- Native timeouts are seconds. Keep configuration and credentials local.
- `extensions/mcp-read-only` preserves exact Supabase/Vercel read allowlists, including nested codemode calls. Linear is unrestricted by this gate. Supabase also uses `read_only=true`.
- The gate protects MCP calls, not shell or direct HTTP access. Colocated tests cover native names and real codemode execution with local mocks; no remote writes or model requests are made.
