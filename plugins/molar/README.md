# Molar plugin

Check a change in a real browser, run plain-English QA tests, explore a site and export Playwright tests with Molar.

Claude Code:

```
/plugin marketplace add pratikranaa/molar-cli
/plugin install molar@molar
```

Codex:

```
codex plugin marketplace add pratikranaa/molar-cli
codex plugin add molar@molar
```

Adds the `molar` skill and the hosted Molar MCP server (`https://api.molar.it/mcp`, OAuth on first use).
The skill drives the `molar` CLI when it is installed: see https://docs.molar.it.

Generated from pratikranaa/Molar `molar-plumbing/packages/cli` (v0.3.13) by `scripts/build-plugin.mjs`.
