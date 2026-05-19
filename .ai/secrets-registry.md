# Secrets registry

Source of truth for runtime-secret consumers per ADR 7 / D12. Every entry uses 1Password CLI (`op run --env-file=<template> -- <cmd>`) at runtime — no sops/agenix, no plaintext-on-disk.

Status values:
- MIGRATED — consumer uses `op run` already; env template lives under `modules/home-manager/secrets/<consumer>.env` (or alongside the consumer)
- TODO — consumer needs migration; env template not yet authored
- BLOCKED — migration depends on something else (note the blocker)

| Consumer | Status | op:// URIs (placeholders) | Template path | Notes |
| -------- | ------ | ------------------------- | ------------- | ----- |
| `~/dotfiles/shell/op.sh` literal token | TODO | `op://Private/Service-Account/token` | n/a (retire at end) | bootstraps the 1Password CLI service-account token; retires once every consumer is migrated |
| Gemini CLI (`gemini-cli`) | TODO | `op://Private/Gemini/api-key` | `modules/home-manager/secrets/gemini.env` | |
| Anthropic (Claude API consumers) | TODO | `op://Private/Anthropic/api-key` | `modules/home-manager/secrets/anthropic.env` | |
| OpenAI (`codex`, AI tools that hit OpenAI) | TODO | `op://Private/OpenAI/api-key` | `modules/home-manager/secrets/openai.env` | |
| GitHub PAT (gh CLI when not using device flow) | TODO | `op://Private/GitHub-PAT/token` | `modules/home-manager/secrets/github.env` | gh CLI may use device flow instead; defer migration unless device flow fails |
| Heroku (`heroku` CLI) | TODO | `op://Private/Heroku/api-key` | `modules/home-manager/secrets/heroku.env` | |
| Stripe (`stripe` CLI) | TODO | `op://Private/Stripe/secret-key` | `modules/home-manager/secrets/stripe.env` | |
| DigitalOcean (`doctl`) | TODO | `op://Private/DigitalOcean/token` | `modules/home-manager/secrets/doctl.env` | |
| `notify.env` (legacy scattered .env) | TODO | unknown — operator audits before migration | n/a | MIGRATION.md ground truth mentions this; needs inspection |
| Tailscale auth (if scripted) | BLOCKED | `op://Private/Tailscale/auth-key` | n/a | Tailscale.app handles login interactively today; only relevant for non-interactive bootstrap |
| Mochi CLI (`mochi`) | TODO | `op://Private/Mochi/api-key` | `modules/home-manager/secrets/mochi.env` | only if user has Mochi configured for CLI |
| Determinate FlakeHub token | BLOCKED | n/a | n/a | FlakeHub auth uses GitHub OAuth, no separate op:// URI today |

## Operator workflow

1. Identify a consumer with a literal secret (in shell init, `.env`, `~/.netrc`, `~/.aws/credentials`, etc).
2. Create or confirm a 1Password vault entry for the secret.
3. Author `modules/home-manager/secrets/<consumer>.env` as an env-template that references `op://...` URIs.
4. Wrap consumer invocations with `op run --env-file=<template> -- <cmd>` (e.g. via an HM zsh function or a wrapper script).
5. Flip the status to MIGRATED here.
6. Remove the literal secret from disk.

## Out of scope

- sops-nix, agenix, age, GPG-encrypted env files.
- Long-lived service-account tokens that themselves bootstrap `op` — those remain a manual install step.
- Discovering all consumers in this session — this registry grows.
