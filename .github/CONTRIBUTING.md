# Contributing

Thanks for helping improve elnora-travel. This is a universal, config-driven Claude Code plugin — contributions must keep it that way.

## Ground rules

1. **Stay universal.** No company-, person-, customer-, or path-specific content anywhere. Examples use the placeholder entities: Acme Corp / Globex / Initech, Jane Doe / Sam Rivera, `example.com`. The CI guard `scripts/check-no-secrets.mjs` enforces this and will fail your PR otherwise.
2. **Config-driven, never hardcoded.** Home airport, currency, companion/room rules, and budget norms come from the traveler-preferences file — never bake a person's defaults into the skill or agent.
3. **Cross-platform.** Everything must work on macOS, Linux, and Windows. Ship shell changes in both `scripts/setup-keys.sh` and `scripts/setup-keys.ps1`.
4. **Respect the free tiers.** SerpApi = 250 searches/mo, RapidAPI booking-com15 = 50 requests/mo hard cap. Any change that adds API calls must keep the quota discipline in the skill and never auto-validate the RapidAPI key.
5. **Never book or pay.** The plugin plans and returns links. Don't add write actions against any travel service.

## Development

```sh
# JS guards
node scripts/check-no-secrets.mjs
node scripts/check-json.mjs

# Shell scripts
bash -n scripts/setup-keys.sh
shellcheck scripts/setup-keys.sh
bash scripts/setup-keys.sh --status
```

## Pull requests

- Use a [Conventional Commit](https://www.conventionalcommits.org/) PR title (`feat:`, `fix:`, `docs:`, `chore:`, …). CI lints this.
- Keep changes surgical and focused. Update docs when behavior changes.
- Fill in the PR checklist.

## Reporting security issues

See [SECURITY.md](SECURITY.md) — do not open a public issue for vulnerabilities.
