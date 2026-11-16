<!-- Adapted from e2e-inc/e2e: skills/e2e/references/mcp.md @ b56e8ed -->
# Driving Molar over MCP

Molar's MCP server gives a coding agent or a chat client the same checks as the CLI: run a goal, verify a claim, extract data, read a trace. Use it when your client speaks MCP and cannot shell out (Claude Chat, ChatGPT), or when you want tool calls instead of commands.

## Contents

- Connect
- Tools
- Workflow
- Local server
- Rules

## Connect

Hosted endpoint, Streamable HTTP with OAuth 2.1 and PKCE: `https://api.molar.it/mcp`. Your client may prompt you to sign in and grant consent. Client login and consent compatibility is still being validated.

`molar init` registers it in `.mcp.json` (Claude Code) and `.cursor/mcp.json` (Cursor), keeping every other server in those files. By hand:

```bash
claude mcp add --transport http molar https://api.molar.it/mcp     # Claude Code
codex mcp add molar --url https://api.molar.it/mcp                 # Codex
```

```json
{ "mcpServers": { "molar": { "type": "http", "url": "https://api.molar.it/mcp" } } }
```

Cursor's `.cursor/mcp.json` takes `{ "url": "..." }` in the same place. Start a new session after you register it so the tools load, then check that `molar_*` tools are listed. Claude.ai and ChatGPT add the same URL as a remote connector.

## Tools

The server's own `tools/list` is the authority; the catalog changes. The ones you will use most:

| Tool | Does |
| --- | --- |
| `molar_verify` | Judge a claim on a page: pass or fail with a rationale |
| `molar_run_task` | Run a goal on an authorized URL; async, returns a `task_id` |
| `molar_agent`, `molar_act` | A multi-step goal, or one imperative action |
| `molar_extract` | Read structured data from a page, read-only |
| `molar_login`, `molar_download` | Sign in with stored credentials; fetch a file |
| `molar_get_task`, `molar_resume_task`, `molar_cancel_task` | Poll, resume, or stop a task |
| `molar_get_trace`, `molar_read_trace_slice`, `molar_get_replay` | Read what a run did |
| `molar_assert_target` | Authorize a domain, as `molar assert-target` |

With `MOLAR_MCP_SURFACE=catalog` set in the server's environment, `tools/list` shows five tools: `molar_tools` (list the catalog or describe one tool), `molar_call` (`{ tool, args }` runs any catalog tool), and `molar_run_task`, `molar_verify`, `molar_get_task`. Call `molar_tools` first, then `molar_call` with arguments that match the schema it printed.

## Workflow

1. `molar_assert_target` for any public domain you do not control yet.
2. Start the work: `molar_verify` for a claim, `molar_run_task` for a goal. A verify may return the verdict directly; a task returns a `task_id`.
3. Poll `molar_get_task` with that `task_id` until it is no longer running. Read `status`, `outcome`, `answer`, `checks`, `error.hint` as you would the CLI result (topic `debugging`).
4. A `paused` task needs input or approval: show the `pause` details to the user, then call `molar_resume_task` with what they give you.
5. For the full record of a run, use its `trace_id` with `molar_get_trace`, not the `task_id`.

## Local server

```bash
molar mcp serve                                       # stdio, for a client that starts the process
molar mcp serve --transport http --port 4200 --json   # HTTP; prints readiness and the endpoint
molar mcp serve --cloud-access --surfaces cartographer,trace
```

- `--cloud-access` lets the tools use the stored login in `~/.config/molar/config.toml`; without it only local surfaces mount.
- `--surfaces` picks from `cartographer`, `clones`, `guards`, `trace`; a missing package is skipped with a note.
- `--json` works only with `--transport http`; stdout carries the protocol in stdio mode (exit `2` otherwise).
- A local stdio entry in `.mcp.json` is `{ "command": "molar", "args": ["mcp", "serve", "--cloud-access"] }`.

## Rules

- Never put a token in an MCP config file. OAuth handles the hosted server; `--cloud-access` reads the stored login.
- Poll with `molar_get_task`; do not start the same task twice because it is slow.
- Honor a pause. Do not resume a task with values the user did not give you.
- Call only tools you saw in `tools/list` or `molar_tools`. A guessed tool name is a failed call.
- Automate only sites you are authorized to (topic `setup`).
