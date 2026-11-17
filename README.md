# donut

Donut — plan your day on a clock

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Plan with Claude (desktop MCP server)

On Linux and Windows, Donut runs a local [MCP](https://modelcontextprotocol.io) server while
it is open, so Claude can read and plan your day. It listens on
`http://127.0.0.1:47821/mcp` (loopback only; requests with a non-local `Host` or `Origin`
are refused). Turn it off or change the port in **Settings › Claude**.

Connect Claude Code (Donut must be running):

```sh
claude mcp add --transport http donut http://127.0.0.1:47821/mcp
```

For Claude Desktop (its custom connectors run from the cloud and can't reach
`127.0.0.1`), bridge it as a local server in `claude_desktop_config.json`:

```json
{"mcpServers": {"donut": {"command": "npx", "args": ["-y", "mcp-remote", "http://127.0.0.1:47821/mcp"]}}}
```

Tools: `get_day`, `list_blocks`, `add_block`, `update_block`, `delete_block`,
`find_free_slots`, `list_activities`, `add_pin`, `delete_pin`. Dates are `YYYY-MM-DD`, times
24h `HH:MM` in local wall-clock time. Changes go through the same code as the dial: they
save instantly, or become sketches you approve with ✓ while Donut is in plan mode.
