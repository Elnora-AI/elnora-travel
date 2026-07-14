# INSTALL_FOR_AGENTS.md

A gated runbook for an AI agent installing elnora-travel for a user. Do the steps in order. Do not skip verification. If a step fails, stop and report — do not proceed.

## Step 1 — Add the marketplace

Run in a shell:

```
claude plugin marketplace add Elnora-AI/elnora-travel
```

(If the CLI is unavailable in your environment, ask the user to run the slash command `/plugin marketplace add Elnora-AI/elnora-travel` instead.)

Verify: `claude plugin marketplace list` includes `elnora-travel`. If not, stop.

## Step 2 — Install the plugin

```
claude plugin install travel-planning@elnora-travel
```

(Slash-command fallback: `/plugin install travel-planning@elnora-travel`.)

Verify: `claude plugin list` shows `travel-planning` enabled. If not, stop.

## Step 3 — Restart Claude Code

The plugin bundles the Airbnb MCP server, which loads on restart. Ask the user to restart Claude Code, then verify the tools `airbnb_search` and `airbnb_listing_details` exist in the new session.

## Step 4 — Keyless smoke test (proves the install before any key work)

Run an Airbnb search through the MCP tool — e.g. `airbnb_search` with `location: "Lisbon, Portugal"` (always region-qualified), a real future `checkin`/`checkout`, `adults: 2`. Verify listings with URLs come back and the returned `searchUrl` coordinates match the intended city. This needs **no API key**; if it fails, the install is broken — stop and report.

## Step 5 — API keys (guided)

Run:

```
/travel-setup
```

It reports current key status, then walks the user through any subset of:

| Key | Unlocks | Where the user gets it |
|-----|---------|------------------------|
| `SERPAPI_API_KEY` | flights + hotel prices | https://serpapi.com/manage-api-key (free, 250/mo) |
| `GOOGLE_MAPS_API_KEY` | routes/distances/places | Google Cloud Console → Maps Platform key; enable **Routes API, Places API (New), Geocoding API** (current-generation — the legacy Directions/Distance Matrix/Places APIs can't be enabled on new projects) |
| `RAPIDAPI_KEY` | Booking.com inventory | rapidapi.com → subscribe `booking-com15` Basic (free, 50/mo hard cap) |

Rules for you, the agent: never echo a pasted key; prefer having the user run the interactive script in their own terminal (`scripts/setup-keys.sh`, or on Windows `powershell -NoProfile -ExecutionPolicy Bypass -File .../setup-keys.ps1`) so the key never enters the chat; save exactly where the command says (macOS/Linux: `~/.config/travel-planning/env`, mode 600; Windows: user-scope env var); validate SerpApi and Google keys live; do NOT auto-validate the RapidAPI key (each call burns 1 of 50/month — ask first).

Verify per key: SerpApi `account.json` returns `plan_searches_left`; Google passes BOTH the geocode check and the Routes API `computeRoutes` check (geocode alone is not enough — see /travel-setup Step 2).

## Step 6 — Keyed smoke test

1. If `SERPAPI_API_KEY` was set: one flight search per the plan-trip skill (any near-future date, e.g. `type=2` one-way) → verify `best_flights` or `other_flights` in the response. This costs 1 of 250 monthly credits — run it once, not per-variant.
2. If `GOOGLE_MAPS_API_KEY` was set: the Routes API validation call in Step 5 already proved routes work; optionally run one Places `searchText` (per the skill) → verify `places[]` comes back.
3. Skip a Booking.com test call unless the user asks — the 50/mo cap is too tight for smoke tests.

## Step 7 — Preferences (optional)

Offer to create the traveler-preferences file (`/travel-setup` Step 4, template: `travel-preferences.example.md`). If the user keeps it inside a git project as `travel-preferences.local.md`, verify it is gitignored.

If everything above passed, the install is complete. Report: which keys are active, the smoke-test results, and one example prompt (`/plan-trip <their city> to Lisbon next month`).

## Notes

- The plugin's own content makes network calls only to: `serpapi.com`, `maps.googleapis.com`, `routes.googleapis.com`, `places.googleapis.com`, `booking-com15.p.rapidapi.com` (all keyed, user-initiated), plus whatever the bundled third-party Airbnb MCP server (`@openbnb/mcp-server-airbnb`, version-pinned) calls.
- The plugin never books, pays, or stores card data — it plans and returns links.
- Quota discipline is built into the skill: SerpApi 250/mo, RapidAPI 50/mo. Don't loop test calls.
