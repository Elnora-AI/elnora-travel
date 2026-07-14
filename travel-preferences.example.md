# Traveler preferences

Copy this file to one of the locations the plan-trip skill checks (first hit wins):

1. anywhere, with the env var `TRAVEL_PLANNING_PREFS` pointing at it
2. `./travel-preferences.local.md` in your project (gitignore it!)
3. `~/.config/travel-planning/preferences.md`

Free-form markdown — the agent reads it as context before planning. Delete what
doesn't apply; add anything else that should shape every trip.

---

## Home base

- Home airport: AMS (Amsterdam). Second option: RTM.
- Default trip origin is home unless I say otherwise.

## Currency & budget

- Quote all prices in EUR.
- Hotels: comfortable mid-range, roughly 80–150/night; flag anything above.
- Flights: economy. A 2h-longer itinerary is worth it above ~120 savings.

## Companions & rooms

- When traveling with my partner Sam: ONE shared double room, `adults=2`,
  `room_qty=1` — never two rooms.
- Solo by default otherwise.

## Luggage & fares

- I always carry an 8kg cabin bag — quote the fare tier that actually includes
  it, not the bare basic fare.

## Loyalty programs

- Star Alliance: prefer when price is close (within ~10%).
- Hotel program: none.

## Other rules

- Stay within a 20-minute commute of wherever the trip's main venue is.
- Late arrivals: only stays with 24h reception or self check-in.
