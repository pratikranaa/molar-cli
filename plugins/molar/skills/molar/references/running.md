<!-- Adapted from e2e-inc/e2e: skills/e2e/references/running.md @ b56e8ed -->
# Running tests

How to run a check, where it runs, what it returns, and how a script or CI reads the answer.

## Contents

- Which command
- Flags
- Local or hosted
- Saved logins
- The result
- Exit codes
- CI
- Rules

## Which command

| Goal | Command |
| --- | --- |
| Judge one claim | `molar verify "<claim>" --url <url> --json` (topic `verify`) |
| Run a plain-English test | `molar test "<objective>" --url <url> --json` |
| Run any goal | `molar run "<goal>" --url <url> --json` |
| Run compiled scenarios | `molar run <scenario-name-or-glob> --ci --json` (the Guard runner) |
| Explore and export tests | `molar explore <url> --json` (topic `explore`) |
| Drive a local browser by hand | `molar browser open <url> --session dev --json`, then `state`, `click`, `input`, `close` |

`molar run` with `--url` treats its argument as a goal; without it, as a scenario name or glob.

## Flags

| Flag | Commands | Effect |
| --- | --- | --- |
| `--json` | all | Structured output: `{ ok, ... }` or `{ ok: false, error: { code, message, hint } }` |
| `--url <url>` | verify, run, test | Target page. `molar test` falls back to `MOLAR_BASE_URL`, then `base_url` in `molar config` |
| `--timeout <ms>` | verify, run, test | Wall clock. Defaults: `120000` (verify, run), `180000` (test). A timeout is a failure with `error.code: "timeout"` |
| `--max-steps <1-500>` | test | Agent step budget (default 100) |
| `--execution auto\|local\|hosted` | verify, run, test | Where the browser runs |
| `--headed` | verify, run, test | Visible browser (a hint) |
| `--profile <name>` | run, test | A saved login; hosted public targets only |
| `--session <name>` | run | An existing session from `molar browser attach`; local only |
| `--authenticate` | run | Reuse or create a verified login before the goal; hosted public targets only |
| `--cache` / `--no-cache` | run | Replay a cached run of the same goal when one exists, or always run the agent |
| `--export <dir>` | run | Write a replay-verified Playwright test (and `.molar.md` for local runs) |
| `--full` | run, test | Add the raw task envelope (artifact manifest, history) to the JSON |
| `--ci`, `--watch`, `--against <env>` | run (scenarios) | CI mode, re-run on change, `local`, `preview`, or `staging` |

`molar <command> --help` lists the rest. Do not use a flag it does not list.

## Local or hosted

`--execution auto` routes private addresses to a local daemon and public URLs to hosted Molar. The local daemon is not included in the published CLI. On a local preflight failure, auto may attempt a hosted fallback; do not use auto for private URLs or send private URLs to hosted Molar. Hosted runs need a publicly reachable URL, `molar login`, and `molar assert-target` (topic `setup`). The result can report `execution_mode` and `fallback_reason`.

## Saved logins

```bash
molar profiles list --json
molar profiles save returning --from-task <task_id> --json      # or --url <url>
molar test "open billing and read the plan name" --url https://app.example.com --profile returning --json
molar profiles delete returning --yes --json
```

A profile is encrypted, belongs to the organization, and works for one origin. It is how a test starts signed in without a password in a command.

## The result

`molar run` and `molar test` print the same compact result:

| Field | Meaning |
| --- | --- |
| `ok`, `pass`, `status` | The verdict. `status` is `passed`, `failed`, `paused`, or `cancelled`; `task_status` is the task's own state |
| `outcome.label`, `outcome.reason` | Whose problem it is: `passed`, `failed`, `blocked`, `incomplete`, `error`, `cancelled` (topic `debugging`) |
| `answer`, `rationale`, `checks`, `final_url`, `steps` | What the agent found and where it ended |
| `task_id`, `trace_id`, `run_url` | Handles for `molar trace export`, the dashboard, and `verify --task-id` |
| `live_view_url` | Where to watch it while it runs, when the runtime offers one |
| `export`, `publication` | Files written by `--export`, and the Guard pull request when `--publish` was used |
| `error: { code, message, hint }` | Present on every non-pass; `hint` says what to do |

## Exit codes

| Code | Meaning |
| ---: | --- |
| 0 | Passed, or the command succeeded |
| 1 | The claim, test, or run did not pass, or the command failed (including an `E_ARGS` the command raises itself, such as `verify` without `--url`). Read `outcome.label` and `error.code` |
| 2 | Flags or arguments the parser rejects (unknown flag, missing required argument), an unknown `molar guide` topic, or no verdict: the run is paused, cancelled, or waiting for approval |
| 20 | Not logged in or no credentials for a hosted run, or an optional surface (`@molar/clones`) is not installed |
| 130 | Interrupted by Ctrl-C or a signal (set by the shell) |

Code `1` covers infrastructure and internal failures too; `outcome.label` of `blocked`, `incomplete`, or `error` separates them from a real failure. `molar guide --json` prints this table.

## CI

```bash
export MOLAR_TOKEN=...            # from the CI secret store
molar doctor --json               # fail fast on a missing login or an unreachable API
molar run checkout --ci --json
molar test "Sign in as the demo user and open the dashboard" --url "$PREVIEW_URL" --json
```

Check the exit code, and keep the JSON as the build artifact. A non-zero exit with `outcome.label` of `blocked` or `error` is worth one rerun before it blocks a merge; a `failed` outcome is not.

## Rules

- Always pass `--json` from a script or an agent, and read it before you decide anything.
- Treat exit `2` as "no verdict", never as a pass.
- Do not raise `--timeout` to hide a stall. Read where it stopped (`live_view_url`, `run_url`, topic `debugging`).
- Do not put `MOLAR_TOKEN` on a command line that CI echoes. Set it in the environment.
- `--no-cache` for one run when you suspect a stale replay; leave the cache on otherwise.
