# elnora-travel

**A real travel agent for Claude Code — live flights, hotels, Airbnb stays, Booking.com inventory, and door-to-door routes, orchestrated into one bookable itinerary. Real APIs, not mocks: it quotes actual prices and hands you actual booking links.**

[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

---

## Install

Pure Claude Code content — no CLI, no build step. Two commands to install (paste the first, hit enter, wait, then the second):

```
/plugin marketplace add Elnora-AI/elnora-travel
```

```
/plugin install travel-planning@elnora-travel
```

Then **restart Claude Code** — the bundled Airbnb MCP server loads at startup. After the restart, **Airbnb search works immediately, with no API key at all.** Unlock the rest:

```
/travel-setup
```

`/travel-setup` walks you through the free API keys (validated live as you paste them) and optionally writes a traveler-preferences file so every trip is planned your way. Prefer the terminal? From a clone of this repo, run `scripts/setup-keys.sh` (macOS/Linux) or `scripts/setup-keys.ps1` (Windows) — same flow, interactive, and your keys never enter a chat session. (The scripts also ship inside the installed plugin; `/travel-setup` prints their exact path.)

Then just ask:

```
/plan-trip Amsterdam to Lisbon, March 10-13, need to be near Baixa
```

…or say "plan my trip to X" in any conversation — the skill triggers on natural language too.

## What it does

| Capability | Source | Key needed |
|---|---|---|
| Live flight search — prices, durations, stops, "is this a good deal" | SerpApi (Google Flights) | `SERPAPI_API_KEY` — free 250 searches/mo |
| Hotel prices across the market | SerpApi (Google Hotels) | same key |
| Real Booking.com inventory + bookable links | RapidAPI `booking-com15` | `RAPIDAPI_KEY` — free 50 req/mo |
| Airbnb stays + listing details | OpenBNB MCP (bundled) | **none** |
| Routes, transit, commute ranking, "what's nearby" | Google Routes API + Places API (New) + Geocoding | `GOOGLE_MAPS_API_KEY` |

The plugin ships three layers that use those sources:

- **`plan-trip` skill** — the playbook: exact API call patterns, quota discipline (it budgets your free tiers instead of burning them), and a planning workflow that ends in one clean itinerary with trade-offs named.
- **`travel-planner` agent** — a sub-agent that runs the whole pipeline: scope → flights → stays (hotels *and* Airbnb, ranked by price/rating/commute) → ground logistics → itinerary. It cross-checks reviews on the open web, verifies venue addresses against the venue's own site (company registries lie), checks fare tiers actually include your cabin bag, and confirms late check-in before recommending a stay for a midnight arrival.
- **Commands** — `/plan-trip` to launch, `/travel-setup` to configure.

**It never books or pays for anything.** It plans, quotes real prices, and hands over links — you click "book".

## Traveler preferences

Optional but worth it: a small markdown file with your home airport, currency, companion/room rules ("traveling with my partner → one double room"), loyalty programs, cabin-bag needs, and budget comfort zone. The agent reads it before every trip. See [`travel-preferences.example.md`](travel-preferences.example.md) — `/travel-setup` can write it for you. Lookup order: `$TRAVEL_PLANNING_PREFS` → `./travel-preferences.local.md` → `~/.config/travel-planning/preferences.md`. It stays on your machine; nothing about you is baked into the plugin.

## Graceful degradation

No keys? Airbnb still works. Each key you add unlocks its column of the table above, and the agent plans with whatever is available while telling you plainly what's missing — it never fabricates a flight or a price.

## Notes & trust boundaries

- One third-party MCP server is fetched by `npx` at plugin load, **pinned to an exact version**: [`@openbnb/mcp-server-airbnb`](https://www.npmjs.com/package/@openbnb/mcp-server-airbnb). Version bumps land via reviewed PRs. Review the package if your threat model requires it.
- The Airbnb server is configured with `--ignore-robots-txt` — without it, Airbnb's robots policy blocks listing search entirely. If you'd rather not, disable the `airbnb` MCP server and the plugin plans with hotels only.
- Keys live in your environment (`~/.config/travel-planning/env`, mode 600, on macOS/Linux; user-scope env vars on Windows) — never in this repo, never in the plugin.
- All API traffic goes direct from your machine with your keys: `serpapi.com`, `booking-com15.p.rapidapi.com`, `routes.googleapis.com`, `places.googleapis.com`, `maps.googleapis.com`; Airbnb traffic goes through the bundled MCP server locally.
- Google note: the plugin uses the **current-generation** Google APIs (Routes API, Places API New, Geocoding). Enable those three on your key's project — the legacy Directions/Distance Matrix/Places APIs can't be enabled on new Google Cloud projects, and this plugin doesn't use them.

## For agents installing this for a user

See [`INSTALL_FOR_AGENTS.md`](INSTALL_FOR_AGENTS.md) — a gated runbook with verification at every step.

## Part of the Elnora family

Open-source agent tooling from [Elnora AI](https://github.com/Elnora-AI) — free, universal, config-driven tools that wire Claude Code (or any AI coding agent) into the systems you run your company on. Each works 100% standalone; install several and they chain into end-to-end workflows.

<!-- ELNORA-FAMILY:START -->
- [elnora-linear](https://github.com/Elnora-AI/elnora-linear) — Linear issue management — search, bulk edit, agents, and a config-driven curator
- [elnora-slack](https://github.com/Elnora-AI/elnora-slack) — the entire Slack Web API as a CLI plus agent skills with a draft-and-approve send gate
- [elnora-whatsapp](https://github.com/Elnora-AI/elnora-whatsapp) — read, search, and send WhatsApp from your own paired account, 100% local
- [elnora-google-workspace](https://github.com/Elnora-AI/elnora-google-workspace) — Gmail, Calendar, Drive, Docs, Sheets, Forms, Tasks, plus any Google API via Discovery
- [elnora-merit-aktiva](https://github.com/Elnora-AI/elnora-merit-aktiva) — Merit Aktiva accounting and Merit Palk payroll as a CLI and plugin
- [elnora-vanta](https://github.com/Elnora-AI/elnora-vanta) — read-only Vanta compliance — frameworks, tests, controls, and vulnerabilities as agent-friendly JSON
- [elnora-luma](https://github.com/Elnora-AI/elnora-luma) — Luma (lu.ma) events — all 61 public API endpoints as a spec-driven CLI with safety guardrails
- [elnora-websearch-tools](https://github.com/Elnora-AI/elnora-websearch-tools) — web search — Exa, Tavily, Perplexity, Firecrawl, and Valyu CLIs and skills in one plugin
- [knowledge-vault](https://github.com/Elnora-AI/knowledge-vault) — an Obsidian-compatible knowledge base for agent teams — search and save your work to any vault
<!-- ELNORA-FAMILY:END -->

## License

[Apache-2.0](LICENSE). Maintained by [Elnora AI](https://github.com/Elnora-AI). Contributions welcome — see [`.github/CONTRIBUTING.md`](.github/CONTRIBUTING.md).
