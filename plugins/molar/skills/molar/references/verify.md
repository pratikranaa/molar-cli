<!-- Adapted from e2e-inc/e2e: skills/create-verification-skill/SKILL.md @ b56e8ed -->
# Checking a change in a real browser

After you change the app, prove the change the way a user would see it. `molar verify` opens the page in a real browser, works toward the claim, and judges what the page shows. Use it before you say a change works.

## Contents

- The command
- Write the claim
- Where it runs
- Read the result
- The loop
- Rules

## The command

```bash
molar verify "<claim>" --url <url> --json
molar verify "<claim>" --task-id <task_id> --json     # judge a claim against what an earlier run found
```

| Flag | Default | Effect |
| --- | --- | --- |
| `--url` | none | The page to start from. One of `--url` or `--task-id` is required |
| `--task-id` | none | A `task_id` from `molar run --json`; hosted only |
| `--execution auto\|local\|hosted` | `auto` | Where the browser runs (below) |
| `--headed` | off | Show the browser; a hint, honored when the runtime can |
| `--timeout <ms>` | `120000` | Wall clock for the run |

Exit `0`: verified. Exit `1`: not verified (or the run broke; read `outcome`). Exit `20`: no credentials for a hosted run.

## Write the claim

A claim is one sentence about what a user can see or do, in the words on the page.

- One outcome per claim. "Signing in shows the dashboard" is one claim. "Sign in, create a project, and invite a teammate" is three; run three commands, so a failure names the step.
- Say what is visible: "the cart badge shows 2", "the page says `Welcome back, Dana`". Not an internal fact ("the session cookie is set").
- When a value appears in several places, say all of them: "the order total is $42.00 in the summary and in the confirmation email subject". The claim holds only if every place agrees.
- Include the start state the flow needs, in the claim: "signed in as the demo user, the settings page lists two API tokens". Use a saved login for real accounts (`--profile` on `molar run`/`molar test`, topic `running`), never a password in the claim.
- Do not paste a secret into a claim. It lands in logs and run pages.

A claim the page cannot show (another page, a database row, something still loading) comes back unverified, not passed. Navigate there in the claim or check it another way.

## Where it runs

The published CLI does not include the local browser daemon. Use a publicly reachable URL you are authorized to test with a hosted login and `molar assert-target <url>` (topic `setup`).

Do not send a private URL to hosted Molar. In `auto` mode a local preflight failure may attempt a hosted fallback, so a private URL is not a supported out-of-the-box workflow. A local execution requires a separately available compatible daemon. The result can report `execution_mode` and `fallback_reason`.

## Read the result

```json
{
  "ok": false,
  "status": "failed",
  "rationale": "The page shows 'Invalid credentials' instead of the dashboard.",
  "answer": "Stayed on /login with an error banner.",
  "checks": [{ "code": "await expect(page).toHaveURL(/dashboard/)", "ok": false }],
  "final_url": "https://app.example.com/login",
  "run_url": "https://app.molar.it/...",
  "execution_mode": "hosted",
  "error": { "code": "assertion_failed", "message": "The claim was not verified.", "hint": "Fix the app or the claim, then run `molar verify` again. Open run_url to see what the browser saw." }
}
```

Read, in this order: `ok` and `status` (the verdict), `outcome.label` when present, `rationale` and `answer` (what the browser saw), `checks` (the failing ones), `final_url`, then `error.hint`. `run_url` opens the run; on a failure `live_view_url` may show where it stalled. Details of each failure kind: topic `debugging`.

## The loop

1. Make the change.
2. Start the app (or confirm it answers: open the URL once, or `curl -sI <url>`).
3. `molar verify "<claim>" --url <url> --json`.
4. Not verified and `outcome.label` is `failed`: the page does not do it. Fix the app, or fix the claim if it asked for something the page never promised. Verify again.
5. Not verified and `outcome.label` is `blocked`, `incomplete`, or `error`: the run did not reach a verdict. Run it once more; if it repeats, narrow the claim or read topic `debugging`.
6. Verified: quote `rationale` or `answer` in your report. Then decide whether the flow deserves a test (topic `writing-tests`).

## Rules

- Never claim a fix works from the diff or from a unit test. The same `molar verify` that failed must now return `ok: true`.
- A pass is a statement about the claim you wrote. A broad claim that passes proves little: make it specific enough that the old bug would have failed it.
- Do not loosen a claim to turn a red result green. If the claim was wrong, say so and why.
- Do not point `verify` at a site you do not run (topic `setup`, "Authorize a domain").
- Do not bypass a `paused` result. It is asking for input; show it to the user.
