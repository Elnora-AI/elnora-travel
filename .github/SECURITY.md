# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| 0.x.x   | Yes       |

## Reporting a Vulnerability

**Please do not open a public GitHub issue for security vulnerabilities.**

Report privately via one of:

- **Email:** [security@elnora.ai](mailto:security@elnora.ai)
- **GitHub Security Advisories:** [Report a vulnerability](https://github.com/Elnora-AI/elnora-travel/security/advisories/new)

Include as much as you can: a description, steps to reproduce, potential impact, and any suggested fix.

## Response Timeline

- **Acknowledgement:** within 48 hours
- **Initial assessment:** within 5 business days
- **Fix and disclosure:** within 90 days

## Scope

**In scope:**

- The plugin content in this repository (skill, agent, commands) and how it handles API keys
- The setup scripts (`scripts/setup-keys.sh`, `scripts/setup-keys.ps1`)
- The CI guards (`scripts/check-no-secrets.mjs`, `scripts/check-json.mjs`)

**Out of scope:**

- The third-party MCP server the plugin loads via `npx` (`@openbnb/mcp-server-airbnb`, version-pinned) — report to its maintainers
- SerpApi, RapidAPI/Booking.com, Google Maps Platform, and Airbnb themselves
- A user's own key handling outside the documented locations

## Data & network behavior (for reviewers)

- API keys are read from the environment; the documented storage locations are `~/.config/travel-planning/env` (mode 600) on macOS/Linux and user-scope environment variables on Windows. Setup scripts read keys with hidden input and validate the character set before saving. Nothing in this repo transmits keys anywhere except the API they belong to.
- Outbound endpoints used by the skill: `serpapi.com`, `maps.googleapis.com`, `routes.googleapis.com`, `places.googleapis.com`, `booking-com15.p.rapidapi.com`. The bundled MCP server additionally reaches Airbnb.
- The Airbnb MCP server is configured with `--ignore-robots-txt` (documented in the README); disable that server if this conflicts with your policy.
- The plugin never books or pays; it has no write access to any travel service.

## Best Practices for Users

- Never commit `travel-preferences.local.md` or any file containing your keys; keep `~/.config/travel-planning/env` at mode 600 (the setup script enforces this).
- Restrict `GOOGLE_MAPS_API_KEY` to the four Maps APIs the plugin uses (Directions, Geocoding, Places, Distance Matrix).
- Prefer per-purpose keys you can revoke — all three services offer free-tier keys that take a minute to rotate.
