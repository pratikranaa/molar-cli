<!-- Adapted from e2e-inc/e2e: skills/e2e/references/writing-tests.md @ b56e8ed -->
# Writing tests

Molar has three ways to hold a check. Pick by what you have:

| You have | Use | Result |
| --- | --- | --- |
| A flow in words, to run now | `molar test "<objective>" --url <url>` | One verdict with evidence; nothing saved |
| A flow you want to keep and run in CI | A `.molar.md` scenario, compiled to Playwright | A file in `.molar/scenarios/`, a spec in `.molar/.compiled/` |
| A flow the agent just walked | `molar run "<goal>" --url <url> --export <dir>` | A replay-verified Playwright test in `<dir>` |
| An existing Playwright, Cypress, Selenium, Puppeteer, or Mabl suite | `molar migrate <path> --local` | `.molar.md` scenarios |

## Contents

- A plain-English test
- A scenario file
- Structure rules
- Compile, validate, run
- Export a Playwright test
- Rules

## A plain-English test

Set `PUBLIC_URL` to a publicly reachable URL you are authorized to test; see topic `setup` for login and target assertion.

```bash
molar test "Sign up with a new email, add the first product to the cart, and reach checkout" \
  --url "$PUBLIC_URL" --json
```

It returns the same evidence envelope as `molar verify` (`ok`, `status`, `answer`, `checks`, `run_url`). `--max-steps <1-500>` caps the agent (default 100); `--timeout <ms>` caps the wall clock (default 180000). `--url` falls back to `MOLAR_BASE_URL`, then `base_url` in `molar config`.

## A scenario file

```bash
molar scenarios add checkout --json      # writes .molar/scenarios/checkout.molar.md
```

A scenario is front matter plus numbered steps:

```markdown
---
spec_version: '1.0'
id: '019301c0-cafe-7000-bea7-deadbeef0010'
slug: login-demo-user
description: The demo user signs in and lands on the dashboard
priority: high
---
# Demo user signs in
## Steps
1. Navigate to /sign-in
2. Fill `input[name=email]` with `demo@example.com`
3. Fill `input[name=password]` with `${secrets.test_password}`
4. Click "Sign in"
5. Assert page URL is /dashboard
6. Assert text "Welcome" is visible
```

Steps start with a verb: `Navigate to`, `Fill ... with`, `Click` (also `hover`, `check`, `select`, `press`, `upload`, `drag`), `Assert`, and `Wait for <event>`. Optional `## Setup` and `## Cleanup` sections hold provisioning and teardown lines. Front matter also takes `tags`, `clones`, `world`, `synthetic_user`, `timeout_ms`, and `mender` (topic `mocks` for `clones` and `world`). `molar scenarios validate --json` names every field it rejects.

## Structure rules

- One behavior per scenario, named for the outcome: `login-demo-user`, not `auth-tests`. A second outcome is a second scenario, so a failing slug says what broke.
- Arrange, act, assert, in that order: reach the starting state (`## Setup`, or a saved login), do the one thing under test, then put every `Assert` last.
- Assert what a user sees: a URL, a visible text, a count. Do not assert on markup that has no meaning to the user.
- Prefer the visible label (`Click "Sign in"`) over a CSS path. When you need a selector, use a stable attribute (`input[name=email]`, `[data-testid=...]`).
- Never write a secret literal. Use `${secrets.<name>}` and keep the value in the vault; name a test account with `credentials_alias` in `.molar.md`. A throwaway account the app itself creates is `${synthetic_user.email}`.
- No fixed waits. An `Assert` compiles to a Playwright expectation, which retries until its timeout: assert the state you need before the next step. `Wait for <event>` is for named events such as a webhook (`Wait for webhook stripe.checkout.session.completed {timeout: 30s}`).
- Reuse a login. Sign in once as a saved profile (`molar profiles save`, topic `running`) and start the scenario on the page it covers.

## Compile, validate, run

```bash
molar scenarios validate .molar/scenarios --json     # a directory, a glob, or one file
molar scenarios compile --json                       # .molar/scenarios/*.molar.md -> .molar/.compiled/<slug>.spec.ts
molar run checkout --ci --json                       # Guard runner; needs @molar/guard-runner
```

Compile skips a file whose hash has not changed; `--force` recompiles. `--out-dir <dir>` moves the output. Read the compiled spec to see the Playwright the scenario became; never edit it.

## Export a Playwright test

```bash
molar run "add the first product to the cart and open the cart" --url "$PUBLIC_URL" \
  --export tests/molar --json
```

The agent runs the goal, then the export is replayed once; only a spec that replays is written. The `export` field of the result lists the files. `molar explore` does this for every scenario it plans (topic `explore`).

## Rules

- Do not write a test you have not run. Run it once and read the result before you commit it.
- A scenario that cannot fail is not a test. Make the last `Assert` something the old bug would have broken.
- Do not commit `.molar/.compiled/` unless the project already does.
- Do not paste real card numbers, tokens, or passwords into a scenario. Stripe's test card `4242424242424242` is fine against a clone or a test-mode account.
- Do not weaken an assertion to make a run pass. Find out whether the app or the test is wrong.
