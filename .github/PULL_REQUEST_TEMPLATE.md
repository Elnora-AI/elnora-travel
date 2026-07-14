<!-- PR title must be a Conventional Commit, e.g. "feat: add train search to plan-trip" -->

## What & why

<!-- What does this change and why? -->

## Checklist

- [ ] `node scripts/check-no-secrets.mjs` passes (no company/person/customer/path-specific strings, no key material)
- [ ] `node scripts/check-json.mjs` passes (manifests valid, no leaked config)
- [ ] Shell changes ship in BOTH `setup-keys.sh` and `setup-keys.ps1`, and `bash -n` + `shellcheck` pass
- [ ] Docs/examples use only generic placeholder entities (Acme / Jane Doe / example.com)
- [ ] No personal defaults hardcoded — traveler specifics live in the preferences file
- [ ] API quota discipline preserved (no new speculative/looping calls; RapidAPI never auto-validated)
