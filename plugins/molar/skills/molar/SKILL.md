---
name: molar
description: Checks a change in a real browser, runs plain-English QA tests, writes and runs Molar scenarios, and explores a site with Molar, the autonomous QA platform (CLI `molar`, MCP server `molar`). Also reads a failed run to find out why it failed and describes the current limits of local vendor clones. Use when a project has a `.molar/` directory or `.molar.md`, when asked to verify, check, or test a change in the running app, to QA or explore a site, to write or run end-to-end or browser tests, when a Molar run fails, or when the `molar` MCP tools are available.
metadata:
  managed-by: molar-cli
  homepage: https://molar.it
---

<!-- Adapted from e2e-inc/e2e: skills/e2e/SKILL.md @ b56e8ed -->

# Molar: check your work in a real browser

Molar launches a real browser, drives the flow you describe, judges what the
page shows, and returns a verdict with evidence: `pass`, `answer`, `checks`,
`run_url`, and an `error.hint` that says what to do next. Use it after you
change code and need proof it works, not a guess.

## Start here: pick the reference for the job

Read the one reference that matches the request before doing anything else.
Each stands on its own. `molar guide <topic>` prints the installed CLI's
version of a reference; prefer it when it differs from this copy. `molar
guide` lists the topics.

| When you are | Topic | Read |
| --- | --- | --- |
| Installing the CLI, logging in, scaffolding a project, running `molar doctor`, authorizing a domain | `setup` | [references/setup.md](references/setup.md) |
| Connecting an agent to the Molar MCP server, picking tools, polling a task | `mcp` | [references/mcp.md](references/mcp.md) |
| Checking that a change you just made works in the running app | `verify` | [references/verify.md](references/verify.md) |
| Writing a `.molar.md` scenario, a plain-English test, or a Playwright export | `writing-tests` | [references/writing-tests.md](references/writing-tests.md) |
| Running tests: flags, local or hosted, saved logins, CI, exit codes, `--json` | `running` | [references/running.md](references/running.md) |
| Reading a failed run: the result JSON, `outcome`, trace, live view | `debugging` | [references/debugging.md](references/debugging.md) |
| Exploring a site toward a goal and exporting tests from what passes | `explore` | [references/explore.md](references/explore.md) |
| Understanding clone support and its current limits | `mocks` | [references/mocks.md](references/mocks.md) |

`molar docs --json` routes by task ("verify a change", "run a task") and lists
the exact commands. Use it when the request fits none of the rows.

## Quick start

Set `PUBLIC_URL` to a publicly reachable URL you are authorized to test. Sign in and assert the target first (topic `setup`). The published CLI does not bundle the local browser daemon.

```bash
molar doctor --json                       # what works on this machine; every check has a hint
molar verify "the login form accepts the demo user and shows the dashboard" \
  --url "$PUBLIC_URL" --json
```


Exit `0` is a pass. Anything else: read the JSON before you act (topic
`debugging`).

## Workflow: you changed the app and want proof

1. `molar doctor --json`. Fix every `fail` check first (topic `setup`).
2. State the claim the way a user would see it: one outcome, the wording on
   the page. `molar verify "<claim>" --url <url> --json` (topic `verify`).
3. Read the result: `ok`, `status`, `outcome.label`, `rationale`, `answer`,
   `checks`, `error`. A pass says what the page showed. Quote that, not a
   guess.
4. On a failure, `outcome.label` says whose problem it is (topic
   `debugging`). `failed`: fix the app or the claim, then verify again.
   `blocked`, `incomplete`, `error`: the run says nothing about the app; run
   it again, narrower, before you change code.
5. When the check should keep running, turn the flow into a test (topic
   `writing-tests`).

## Rules

- Read the run result JSON before you claim a fix works. A change is fixed
  when the same `molar verify` or `molar test` that failed now returns
  `ok: true`, not when the code looks right.
- Never paste secrets into a command line you will keep, a scenario, a test
  file, a commit, or a chat message. A token goes in `MOLAR_TOKEN` or the
  `molar login` prompt; a test account is a `credentials_alias` in
  `.molar.md`. Never print `~/.config/molar/` contents.
- Use `--json` in every command an agent runs and act on `error.hint`. Never
  invent a flag: `molar <command> --help` lists the real ones.
- Automate only sites you are authorized to. Public domains need `molar
  assert-target <url>` first; `localhost` and private addresses do not.
- A `paused` result (exit `2`) is the task asking for input or approval. Show
  it to the user; do not retry it blindly or work around it.
- One claim per `verify`, one goal per `test`. Two outcomes are two commands,
  so a failure names what broke.
- `blocked`, `incomplete`, and `error` outcomes are not evidence that the app
  is broken or fixed. Run again before you change code.
- Do not add sleeps or retries to hide a flaky check. Find what the page was
  waiting for and say it in the claim.
- `.molar/` holds scenarios and compiled specs. Read `.molar/.compiled/`,
  never edit it; recompile with `molar scenarios compile`.

## Feedback

When Molar itself gets in your way (a command or flag that behaves against
its own help, docs that misled you), tell the user in your final message with
the command, the `error.code`, and what you expected. Do not report failures
of the app under test.
