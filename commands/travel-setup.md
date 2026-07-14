---
description: Guided setup — API keys for flights/hotels/routes (validated live) plus an optional traveler-preferences file
---

# /travel-setup — configure the travel-planning plugin

Walk the user through API keys and preferences. Be brief and concrete; one thing at a
time. Never echo a pasted key back, never write a key anywhere except the locations
below, and redact keys from any command output you show.

## Step 0 — offer the private path first

The most key-hygienic flow is the interactive script in the user's **own terminal** —
the key never enters this chat. Offer it first:

- macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-keys.sh"`
- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/setup-keys.ps1"`

(Substitute the actual plugin root path when you print these.) The script prompts with
hidden input, validates each key live, and saves it. If the user runs it, skip to
Step 4. If they'd rather paste keys here, tell them plainly: *a key pasted in chat is
stored in the local session transcript on this machine* — fine for most personal
setups, their call — then continue with Step 1.

## Step 1 — current status

Run the status check (non-interactive):

- macOS/Linux: `bash "${CLAUDE_PLUGIN_ROOT}/scripts/setup-keys.sh" --status`
- Windows: `powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_PLUGIN_ROOT}/scripts/setup-keys.ps1" -Status`

Show the user the result and explain: **Airbnb search already works with no key.** The
three optional keys unlock more:

| Key | Unlocks | Free tier | Get it at |
|-----|---------|-----------|-----------|
| `SERPAPI_API_KEY` | Live flights + hotel prices | 250 searches/mo | https://serpapi.com/manage-api-key |
| `GOOGLE_MAPS_API_KEY` | Routes, distances, commute ranking, places | generous free monthly usage | Google Cloud Console → Maps Platform → create key; enable **Routes API, Places API (New), Geocoding API** (the current APIs — legacy Directions/Distance Matrix/Places can't be enabled on new projects) |
| `RAPIDAPI_KEY` | Real Booking.com inventory + booking links | 50 requests/mo, hard cap | rapidapi.com → subscribe to `booking-com15` (Basic, no card) |

Ask which they want to set up now (any subset; recommend starting with SerpApi — it's
the fastest signup and unlocks the most).

## Step 2 — collect and save each key

For each key the user wants: give them the exact link, wait for them to paste the key,
then save it **without displaying it**. Valid keys match `^[A-Za-z0-9_-]{8,}$` — if the
paste doesn't, it got mangled; ask for a re-paste rather than saving it.

**macOS/Linux** — append to the plugin key file (create dir, dedupe the var, lock perms):

```bash
umask 077; mkdir -p ~/.config/travel-planning && touch ~/.config/travel-planning/env && chmod 600 ~/.config/travel-planning/env
grep -v '^export SERPAPI_API_KEY=' ~/.config/travel-planning/env > ~/.config/travel-planning/env.tmp || true
echo "export SERPAPI_API_KEY='<PASTED_VALUE>'" >> ~/.config/travel-planning/env.tmp
mv ~/.config/travel-planning/env.tmp ~/.config/travel-planning/env && chmod 600 ~/.config/travel-planning/env
```

**Windows** — per-user environment variable (also set it in-process so this session can use it):

```powershell
[Environment]::SetEnvironmentVariable("SERPAPI_API_KEY", "<PASTED_VALUE>", "User")
```

Then validate immediately. On macOS/Linux, source the key file first so the just-saved
key is in scope — and never inline the key itself into the validation command:

- SerpApi: `. ~/.config/travel-planning/env && curl -s "https://serpapi.com/account.json?api_key=$SERPAPI_API_KEY" | grep -o '"plan_searches_left": *[0-9]*'` → valid if a number comes back (that's their remaining quota — report it). The grep keeps the account details (and the echoed key) out of the output.
- Google: `. ~/.config/travel-planning/env && curl -s "https://maps.googleapis.com/maps/api/geocode/json?address=Paris&key=$GOOGLE_MAPS_API_KEY" | grep -o '"status" *: *"[A-Z_]*"'` → needs `"OK"`; **then also** the Routes API check (POST `computeRoutes` Paris→Versailles per the plan-trip skill, field mask `routes.duration`) → valid if a `duration` comes back. Geocoding passing alone does NOT mean routes will work — if Routes fails with `PERMISSION_DENIED`, tell them to enable "Routes API" (and "Places API (New)") on the project and re-check.
- RapidAPI: do NOT auto-validate (each call burns 1 of the 50/month). Ask first; if yes: `searchDestination?query=Paris` per the plan-trip skill → valid if `"status":true`.
- On Windows, validate by re-running the status check from Step 1 (`-Status` reads the User-scope variable back from the registry, so it works without a restart).

If validation fails, say exactly what to fix and re-collect.

## Step 3 — make the keys available everywhere (macOS/Linux, optional)

The plan-trip skill sources `~/.config/travel-planning/env` before its curl calls, so
the plugin works with no further wiring. If the user also wants the keys in their own
shells, offer to add this line to their `~/.zshrc` / `~/.bashrc` (skip if already present):

```
[ -f ~/.config/travel-planning/env ] && . ~/.config/travel-planning/env  # travel-planning plugin keys
```

Windows needs nothing extra — but the user must **restart Claude Code** so its tools
inherit the new User-scope variables.

## Step 4 — traveler preferences (optional, recommended)

Ask if they want a preferences file so every trip is planned their way. If yes, ask
briefly for: home airport/city, preferred currency, who they usually travel with (and
room rules, e.g. partner → one double room), loyalty programs, cabin-bag needs, budget
comfort zone. Write the answers to `~/.config/travel-planning/preferences.md` using
`travel-preferences.example.md` in the plugin root as the template. Point out the file
is theirs to edit and is never committed anywhere.

## Step 5 — wrap up

Re-run the status check from Step 1 and show it. Remind them: on Windows (or if they
added the rc line on macOS/Linux and want it in already-open terminals), open a fresh
terminal — and on Windows restart Claude Code. Then suggest trying:

```
/plan-trip <origin> to <destination>, <dates>
```
