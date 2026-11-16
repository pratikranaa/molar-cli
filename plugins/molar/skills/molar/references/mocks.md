# Hermetic tests with Clones

Clones model third-party vendors such as Stripe, Twilio, email, auth, and S3. Self-service CLI clone provisioning is not currently published; availability depends on a separately configured installation.

## Contents

- Pick a clone
- Declare clones in a scenario
- Start one by hand
- Over MCP
- Rules

## Pick a clone

| Kind | Stands in for | Typical use |
| --- | --- | --- |
| `stripe` | Stripe | Checkout, subscriptions, webhooks |
| `twilio` | Twilio | SMS and voice, one-time codes |
| `email` | A mailbox | Welcome and reset emails; read the outbox |
| `auth` (`clerk` in scenario front matter) | An identity provider | Sign-in and synthetic users |
| `s3` | Object storage | Uploads and downloads |

State is seeded and deterministic: the same seed gives the same ids, and a world can be snapshotted and restored between attempts.

## Declare clones in a scenario

List the clones the scenario needs in its front matter. This is scenario syntax; it does not establish that the published runner provisions them. Do not assume a scenario provisions clones.

```markdown
---
spec_version: '1.0'
id: '019301c0-cafe-7000-bea7-deadbeef0011'
slug: checkout-pro-plan
description: Subscribe to Pro; receive the welcome email
priority: critical
clones:
  - { kind: stripe, seed: stripe-base }
  - { kind: email }
---
# Pro plan checkout
## Steps
1. Navigate to /pricing
2. Click "Subscribe Pro"
3. Fill `input[name=cardNumber]` with `4242424242424242`
4. Click "Pay $20"
5. Assert text "Welcome to Pro" is visible
6. Assert Email Clone outbox contains 1 email to `${run.user.email}`
```

A named world expands to a set of clones: `world: commerce` (also `messaging`, `identity`, `collaboration`, `storage`, `platform`). A custom world name needs a `clones:` list beside it. `molar docs hermetic-world-packs --json` prints the details; `molar scenarios validate --json` rejects an unknown world.

The project's `.molar.md` can list the clones the whole app uses under `## Clones`.

## Start one by hand

```bash
molar clone stripe --start --seed stripe-base --json    # { kind, started, url, admin_url }
molar clone stripe --stop --json
```

Point the app's vendor base URL at the `url` it prints, then run the check. `molar clone` needs `@molar/clones`; without it the command exits `20` with `E020` and a hint. The optional package is not currently published for self-service installation; scenario metadata alone is not a substitute for provisioning.

## Over MCP

With the Clones surface mounted (`molar mcp serve` with `MOLAR_CLONES_CTRL_URL` set, or `--cloud-access`): `molar_clone_spawn`, `molar_clone_list`, `molar_clone_seed`, `molar_clone_world` (snapshot or restore), `molar_clone_route`, `molar_clone_trace`, `molar_clone_stop`. Topic `mcp` covers the connection.

## Rules

- Point tests at a clone or a vendor's test mode, never at a live vendor with real keys or real cards. Stripe's test card `4242424242424242` belongs to a clone or a test-mode account.
- Never paste a vendor secret into a scenario. Keep keys in the vault and reference `${secrets.<name>}`.
- Clones are for tests you own. Do not use one to bypass a vendor's rules on a site you do not run.
- Stop what you started: `molar clone <kind> --stop`. Do not kill processes by name.
- A clone is a model of the vendor. When a bug only shows against the real vendor, say so rather than closing it on the clone's behavior.
