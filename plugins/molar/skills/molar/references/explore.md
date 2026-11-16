<!-- Adapted from e2e-inc/e2e: skills/e2e/references/explore.md @ b56e8ed -->
# Exploring a site

`molar explore` starts from one URL, explores it read-only, plans a few concrete scenarios from what it saw, runs each, and writes a replay-verified Playwright test for every one that passes. Use it to learn what a site can do, or to get a first suite.

## Contents

- Commands
- What a run does
- Start signed in
- Reading the result
- Rules

## Commands

```bash
molar explore https://shop.example.com --out-dir tests/molar --json
molar explore https://app.example.com --intent "cover signup and account settings" --max-scenarios 3 --json
molar plan --url https://app.example.com --goal "test checkout" --json            # plan only, nothing runs
molar plan --url https://app.example.com --goal "test checkout" --run --yes --export tests/molar --json
```

| Flag | Default | Effect |
| --- | --- | --- |
| `--intent <text>` (explore), `--goal <text>` (plan) | `the main user flows` | What to prioritize |
| `--out-dir <dir>` (explore), `--export <dir>` (plan) | `molar-tests` for explore | Each passing scenario's test goes to `<dir>/<n>-<name>` |
| `--profile <name>` | none | A saved login: explore and test signed in |
| `--max-scenarios <n>` | all planned | Run at most `n` scenarios; the cost cap |
| `--max-steps <1-500>` | server default | Step budget per task |
| `--max-budget <cents>` | none | Spend budget per task, in US cents |
| `--timeout <ms>` | `600000` | Per-task timeout |
| `--run`, `--yes` (plan) | off | Run the plan; `--yes` approves it without a terminal |

Both run on hosted Molar and need `molar login` (exit `20` otherwise). A `localhost` URL is not reachable from there; expose a preview or staging URL, and `molar assert-target` it.

## What a run does

1. Plans: an exploration task reads the site without changing anything and proposes scenarios. Irreversible ones (a purchase, a deletion) are dropped.
2. Runs each scenario as its own task, one browser at a time.
3. Exports each passing scenario as a Playwright test and replays it once; only a test that replays is written, and its row says `export: "verified"`.
4. Returns one suite: `PASSED`, `FAILED`, or `BLOCKED` per scenario.

## Start signed in

```bash
molar profiles save app-login --url https://app.example.com --json
molar explore https://app.example.com --profile app-login --intent "cover billing" --json
```

The planning run and every scenario start from that login, so no scenario is spent signing in (topic `running`, "Saved logins").

## Reading the result

`--json` returns `{ plan_task_id, plan, suite: [{ test, verdict, task_id, run_url?, reason, export? }], passed, failed, blocked, skipped_over_max_scenarios? }`.

- The exit code is `0` when the command finished, not when every scenario passed. Read `failed` and `blocked` and each `suite[].verdict`.
- `BLOCKED` is a site refusal or an outage, not a finding. Run that scenario again later.
- `reason` says why a scenario failed; `run_url` opens it. Open topic `debugging` for the failure kinds.
- An `export` that is not `verified` is an error code: the scenario passed but its test did not replay. Do not commit that test.

## Rules

- A failed scenario is a candidate, not a confirmed bug. Check it with `molar verify "<the expected behavior>" --url <page> --json` before you report it as a defect.
- Cap spend: set `--max-scenarios` first on a new site, then raise it.
- Explore only sites you are authorized to. It plans and runs real interactions; irreversible ones are dropped, but a read-only crawl still loads their pages.
- Do not commit exported tests you have not read. Run each once (topic `running`) and keep the ones that assert something a user would care about.
- Do not paste credentials into `--intent`. Use `--profile`.
