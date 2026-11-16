# Molar CLI releases

This repository is the public, unauthenticated distribution surface for the
[Molar](https://molar.it) universal browser-automation and verification CLI.
Source builds run in `pratikranaa/Molar`; this repository contains the agent plugin, release artifacts, and the fail-closed installer.

## Agent plugin

The plugin adds the Molar skill and the hosted MCP server. Connecting the server requires Molar OAuth; the CLI skill requires the separately installed CLI and a publicly reachable target you are authorized to test. The published CLI does not include the local browser daemon.

Claude Code, inside a session:

```text
/plugin marketplace add pratikranaa/molar-cli
/plugin install molar@molar
```

On Claude Code v2.1.275 or newer, the one-shot form is `/plugin install molar --marketplace pratikranaa/molar-cli`.

Or from a terminal:

```sh
claude plugin marketplace add pratikranaa/molar-cli
claude plugin install molar@molar
```

Codex:

```sh
codex plugin marketplace add pratikranaa/molar-cli
codex plugin add molar@molar
```

The plugin and skill are licensed under Apache-2.0; see [LICENSE](LICENSE).

## Install

Install [Cosign](https://docs.sigstore.dev/cosign/system_config/installation/),
then run:

```sh
curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | sh
```

Use a user-writable directory when `/usr/local/bin` is unavailable:

```sh
curl -fsSL https://raw.githubusercontent.com/pratikranaa/molar-cli/main/install.sh | \
  sh -s -- --install-dir "$HOME/.local/bin"
```

The installer refuses to install unless both the SHA-256 checksum and keyless
Sigstore bundle verify. The pinned certificate identity is:

```text
https://github.com/pratikranaa/Molar/.github/workflows/release-cli.yml@refs/tags/v*
```

The expected OIDC issuer is `https://token.actions.githubusercontent.com`.

## Manual verification

Download a platform binary and its matching `.cosign.bundle`, then run:

```sh
cosign verify-blob \
  --bundle molar-darwin-arm64.cosign.bundle \
  --certificate-identity-regexp '^https://github\.com/pratikranaa/Molar/\.github/workflows/release-cli\.yml@refs/tags/v' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com \
  molar-darwin-arm64
```

Release assets are available on the [Releases](https://github.com/pratikranaa/molar-cli/releases) page.
