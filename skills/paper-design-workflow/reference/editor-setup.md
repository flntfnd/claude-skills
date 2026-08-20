# Paper MCP: Per-Editor Setup

Paper Desktop must be running with a file open — the MCP server starts automatically and runs locally at `http://127.0.0.1:29979/mcp`. No cloud dependency, files stay on disk.

## Claude Code

```bash
# Add the Paper plugin marketplace
/plugin marketplace add paper-design/agent-plugins

# Install the Paper Desktop plugin
/plugin install paper-desktop@paper
```

Verify with `/mcp` — Paper should appear in the list.

## Cursor

```
/add-plugin paper-desktop
```

Or install via the Cursor Marketplace. Verify in `Cursor Settings > Tools & MCP`. Reload the window or toggle the MCP off/on if the agent doesn't see it.

## Codex

`Settings > MCP Servers` → Add custom MCP → "Streamable HTTP" tab → name `paper`, URL `http://127.0.0.1:29979/mcp`.

## Copilot (VS Code)

Create `.vscode/mcp.json`:

```json
{
  "servers": {
    "paper": {
      "type": "http",
      "url": "http://127.0.0.1:29979/mcp"
    }
  }
}
```

Click "Start" above the word "paper" in the file.

## Antigravity

Open MCP store → Manage MCP Servers → View raw config → modify `mcp_config.json`:

```json
{
  "mcpServers": {
    "paper": {
      "serverUrl": "http://127.0.0.1:29979/mcp"
    }
  }
}
```

## OpenCode

Add to `opencode.json`:

```json
{
  "mcp": {
    "paper": {
      "type": "remote",
      "url": "http://127.0.0.1:29979/mcp",
      "enabled": true
    }
  }
}
```

## Verifying the connection

Open a chat: "create a red rectangle in Paper." The agent should ask permission, then create the rectangle visibly in the document.

## When MCP fails

Most common cause: long-running agent sessions. Restart the agent session first. If that fails, restart the host (Cursor, Claude Code, Codex, Copilot). LLMs occasionally hallucinate tool parameters even with the schema in context — the fix is the same: restart everything.

WSL users: enable mirrored mode networking (`networkingMode: mirrored` in WSL config) to reach `127.0.0.1`.
