<!-- Adapted from e2e-inc/e2e: skills/e2e/references/setup.md @ b56e8ed -->
# Setting up Molar

Install the CLI, sign in, scaffold a project, and prove the machine can run a check. Every command here is non-interactive with `--json`.

## Contents

- Install and check
- Sign in
- Scaffold the project
- Authorize a domain
- Configuration and environment
- Rules

## Install and check

```bash
npm install -g @molar/cli      # Node 18 or newer
molar version --no-remote --json
molar doctor --json
```

`molar doctor --json` prints `{ ok, schemaVersion: "doctor-1", version, checks: [...] }`. Each check is `{ id, status, message?, hint? }` with `status` one of `pass`, `warn`, `fail`, `skip`, `unknown`:

- `fail` stops a run: an old Node, a rejected token, an unreachable API. Fix it first. The exit code is `1`.
- `warn` is something a run can work around: not logged in, no skill installed, an optional surface missing.
- `skip` does not apply here (`--offline` skips the network checks). `unknown` is what doctor could not tell.
- Every non-`pass` check carries a `hint`: the command to run next.

`molar doctor --offline --json` skips the login and API checks; use it with no network.

## Sign in

A hosted run needs credentials and a publicly reachable URL. The local browser daemon is not included in the published CLI, so a fresh install cannot run localhost or private-address checks as a supported out-of-the-box workflow. Do not send private URLs to the hosted service.

```bash
molar whoami --json                         # who the stored token is, or E_AUTH
molar login --api-url <url> --json          # reads MOLAR_TOKEN and MOLAR_API_URL; without them it prompts for a PAT in a terminal
```

Create a Personal Access Token in the dashboard under Settings, API Tokens, and give the human's terminal the token, not the chat. `molar login --json` never prompts: it needs `MOLAR_TOKEN` (or `--token`) and fails with `E_AUTH` and a hint otherwise.

An agent with no human at the keyboard can register itself. A human then confirms with one email code:

```bash
molar agent signup --human-email <email> --name "<agent name>" --harness claude-code --json
molar agent signup status --json
molar agent signup verify --code <6-digit code the human read from the email> --json
```

Stop after `signup` and ask the human for the code. Do not guess it or try to read their mailbox.

`molar agent init --json` is the one-call bootstrap: it checks the stored token against `/api/v1/me`, checks the control plane and the Cartographer API, and scaffolds the project. It returns `ok: false` with `error.code` `E_NOT_CONFIGURED`, `E_AUTH`, or `E_UNREACHABLE` and a `hint` when it cannot finish; it never creates an account.

## Scaffold the project

```bash
molar init --json                 # or: molar agent init --json
```

`molar init` writes, and skips whatever already exists:

| Path | Holds |
| --- | --- |
| `.molar.md` | The app: `base_url`, auth alias, clones, scenario intents |
| `.molar/scenarios/` | `*.molar.md` scenarios (topic `writing-tests`) |
| `.molar/.compiled/` | Compiled Playwright specs; generated, never edited |
| `.molar/config.toml` | Project-local settings |
| `AGENTS.md`, `.cursorrules` | Short notes for coding agents |
| `.claude/skills/molar/`, `.agents/skills/molar/` | This skill, the installed CLI's version, with every reference |
| `.mcp.json`, `.cursor/mcp.json` | The `molar` MCP server entry (topic `mcp`) |

Run it again any time: it is idempotent and refreshes an installed skill that is out of date. The `--json` result lists `created`, `skipped`, and per-file `skill` and `mcp` outcomes (`created`, `updated`, `unchanged`, `skipped`). `--no-skills` and `--no-mcp` leave those out.

Then set the one fact every command needs, the app's URL:

```bash
molar config set base_url "$PUBLIC_URL"    # molar test reads it when --url is missing
```

## Authorize a domain

Molar refuses to automate a site its user has not asserted authority over. `localhost` and private addresses are exempt.

```bash
molar assert-target https://staging.example.com --json
```

Run it once per domain you own or operate. A refusal comes back with an `error.hint`; do not work around it, and do not point Molar at a site you do not run.

## Configuration and environment

| Variable | Meaning |
| --- | --- |
| `MOLAR_TOKEN` | Bearer token; wins over the stored login and is never written to disk |
| `MOLAR_API_URL` | Control plane URL (default `https://api.molar.it/plumbing-api`) |
| `MOLAR_CARTOGRAPHER_API_URL` | Execution API for `verify`, `run`, `test`, `assert-target` |
| `MOLAR_BASE_URL` | Default `--url` for `molar test` |

`molar config list --json` shows the stored profile with the token masked.

## Rules

- A token goes in `MOLAR_TOKEN` or the `molar login` prompt. Never write it into `.molar.md`, a scenario, a test, `AGENTS.md`, a commit, or a message to the user.
- Do not read or print `~/.config/molar/`.
- `molar doctor --json` first, every time something looks off. Fix `fail` checks before reading anything else.
- Do not create accounts for the user. `agent signup` asks a human; leave the code to them.
- Ask before you install the CLI globally on a machine you do not own, and before you change `.mcp.json` outside what `molar init` writes.
