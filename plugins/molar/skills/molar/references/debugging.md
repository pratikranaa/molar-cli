<!-- Adapted from e2e-inc/e2e: skills/e2e/references/debugging.md @ b56e8ed -->
# Debugging a failed run

Read what the run recorded before you change code. It already saw the page.

## Contents

- Read the failure
- Whose problem is it
- Error codes
- Look at the run
- Flaky checks
- Is it the app

## Read the failure

Run the failing command again with `--json` if you do not have its output, then read in this order:

1. `ok`, `status`: the verdict. `paused` and `cancelled` are not failures of the app.
2. `outcome.label` and `outcome.reason`: whose problem it is (next section).
3. `rationale`, `answer`: what the browser saw, in words. Compare it with the claim.
4. `checks`: each `{ code, ok }`; the `ok: false` ones are what did not hold.
5. `final_url`, `steps`: where the run ended and how long it took. A final URL that is not the page you expected is usually the answer.
6. `error.code` and `error.hint`: the next step, written for you.
7. `run_url`, `live_view_url`: open them when the text is not enough.

`--full` adds the raw task envelope (artifact manifest, history) when you need it; it is long, so ask for it only then.

## Whose problem is it

`outcome.label` separates a real failure from a run that never reached a verdict:

| Label | Means | Do |
| --- | --- | --- |
| `passed` | The goal was reached | Nothing |
| `failed` | The site does not do it, or the claim is false | Fix the app, or fix the claim if it promised too much; run again |
| `blocked` | The site refused the browser or was down | Run again later. Says nothing about the app |
| `incomplete` | Molar's agent did not finish | Run again, or give a narrower goal. Not evidence the app is broken |
| `error` | Molar hit an internal problem | Run again. Not the app |
| `cancelled` | Someone stopped it | Run again if you still need it |

Do not edit code on a `blocked`, `incomplete`, or `error` result. Run it once more first.

## Error codes

| `error.code` | Usual cause | Fix |
| --- | --- | --- |
| `assertion_failed`, `task_failed` | The page did not show what the claim says | Compare `rationale` with the claim; fix the app or the claim |
| `timeout` | The run exceeded `--timeout` | Open `live_view_url` or `run_url` to see where it stalled; narrow the goal; raise `--timeout` only if the page is genuinely slow |
| `task_paused` | The task is waiting for input or approval (exit `2`) | Show `pause` to the user; do not retry blindly |
| `task_cancelled` | The task was stopped (exit `2`) | Run it again |
| `E_AUTH` | No stored token, or the control plane rejected it (exit `20`) | `molar whoami --json`, then `molar login` (topic `setup`) |
| `E_ARGS` | A required flag is missing, such as `--url` | Fix the call the `hint` names |
| `E_UNREACHABLE`, `E_UPSTREAM` | The control plane or Cartographer API is down or unreachable | `molar doctor --json`; retry shortly |
| `invalid_target_url` | The URL is not absolute `http(s)` or carries credentials | Pass a plain URL; log in with a profile instead |
| `daemon_unavailable`, `daemon_start_failed` | The local browser daemon cannot start | Read `error.hint`; `molar doctor --json`; for a public URL use `--execution hosted` |
| `local_task_id_unsupported` | `--task-id` with `--execution local` | Use `--execution hosted` or `auto` |
| `E020` | An optional surface is not installed (exit `20`) | Install the package the message names |
| `E_TRACE_NOT_FOUND` | A `trace_id` that does not exist in this organization | Use `trace_id` from the result, not `task_id` |

## Look at the run

```bash
molar run "<goal>" --url <url> --headed --json            # watch it
molar trace export <trace_id> --format markdown -o trace.md   # step-by-step text; also summary, ndjson, playwright, video, rrweb
molar trace open <trace_id>                               # the dashboard page; a path to trace.zip opens Playwright's viewer
molar trace diff <trace_a> <trace_b> --json               # what changed between a pass and a fail
molar browser open <url> --session dev --json             # look at the page yourself, then `state`
```

`trace_id` comes from the run result; `task_id` is not a trace id. For a Guard run, `molar explain <guard-run-id> --json` and `molar guard failures --json` explain it against its last good evidence, and `molar mender status --run <id> --json` shows the proposed fix.

## Flaky checks

- A claim that mixes two outcomes fails on whichever the page shows slower. Split it (topic `verify`).
- A value that is shown in several places and updates at different times: say each place in the claim.
- Replay of a cached run: rerun once with `--no-cache` to rule out a stale replay.
- Shared data: use a fresh account per run (`${synthetic_user.email}` in a scenario) instead of a shared one.
- Measure a fix: run the same command three times; one pass is not proof.
- Do not add sleeps or blind retries. Find what the page waited for and put it in the claim.

## Is it the app

A check that fails every run at the same place with the same `rationale` is a bug or a changed page, not a flake. Reproduce once with `--headed`, then fix the app, or update the claim and the page together. A `blocked` result on a site you run usually means its bot protection or an outage; say so rather than guessing.
