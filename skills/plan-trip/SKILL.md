---
name: plan-trip
description: >
  Plan a trip end to end using live data — flights, hotels, Airbnb stays, and ground
  routes. Use when the user asks to "plan a trip", "find flights", "find a hotel",
  "find an Airbnb", "book travel", "where should I stay", "how do I get from X to Y",
  "best route", "travel itinerary", "plan my travel to <place>", or gives travel dates
  and destinations. Covers flight search (Google Flights), hotel search (Google Hotels),
  Booking.com inventory, Airbnb listings, and driving/transit routes + distances (Google Maps).
---

# Plan a Trip

Plan trips with real, live data from four sources. Flights, hotels, Booking.com
inventory, and routes/places all go over `curl`; Airbnb comes from an MCP server
bundled with this plugin.

## Tools available

| Need | How to call | Auth |
|------|-------------|------|
| **Flights** | `curl` SerpApi `engine=google_flights` | `SERPAPI_API_KEY` |
| **Hotels (aggregated prices)** | `curl` SerpApi `engine=google_hotels` | `SERPAPI_API_KEY` |
| **Hotels (Booking.com inventory)** | `curl` RapidAPI `booking-com15` | `RAPIDAPI_KEY` |
| **Airbnb stays** | MCP tools `airbnb_search`, `airbnb_listing_details` | none |
| **Routes / distances / places** | `curl` Google Routes API, Places API (New), Geocoding API | `GOOGLE_MAPS_API_KEY` |

SerpApi free tier = **250 searches/month**. Each non-cached `curl` call = 1 credit.
Airbnb and Google Routes/Places calls do not count against that quota. Be economical:
one flight search and one hotel/Airbnb search usually suffice — don't re-query
speculatively. Google's APIs have generous free monthly usage; use them freely for
routes and "what's nearby", just don't loop them pointlessly.

Booking.com (RapidAPI `booking-com15`) free tier = **50 requests/month, hard limit**.
Very tight — a hotel lookup costs 2 calls (`searchDestination` + `searchHotels`). Use it
only when the user wants real Booking.com inventory/links; otherwise prefer SerpApi
`google_hotels` for a quick price read. Never poll it.

## Setup & keys

Keys are read from environment variables: `SERPAPI_API_KEY`, `GOOGLE_MAPS_API_KEY`,
`RAPIDAPI_KEY`. Before any `curl` call, load the plugin's key file defensively (it's
where the setup script saves keys on macOS/Linux; harmless if absent — note the
`if` form so a missing file doesn't fail the command):

```bash
if [ -f ~/.config/travel-planning/env ]; then . ~/.config/travel-planning/env; fi
```

**Missing keys degrade gracefully — plan with what's available and say what's missing:**

| Keys set | What works |
|----------|-----------|
| none | Airbnb search + listing details (no key needed) |
| `SERPAPI_API_KEY` | + live flights and hotel prices |
| `GOOGLE_MAPS_API_KEY` | + routes, distances, commute comparison, places |
| `RAPIDAPI_KEY` | + real Booking.com inventory and bookable links |

If a key the user needs is missing, point them to `/travel-setup` (guided, validates
each key live) or the raw scripts: `${CLAUDE_PLUGIN_ROOT}/scripts/setup-keys.sh`
(macOS/Linux) / `setup-keys.ps1` (Windows). Free keys:
SerpApi → https://serpapi.com/manage-api-key · Google → Google Cloud Console
(enable **Routes API, Places API (New), Geocoding API** — the current-generation
APIs; the legacy Directions/Distance Matrix/Places APIs can't be enabled on new
projects) · RapidAPI → https://rapidapi.com (subscribe to `booking-com15`, free
Basic plan).

If a Google call returns 403 `PERMISSION_DENIED`, the key is wrong or that specific
API isn't enabled on the project — the error message names which. If Booking.com
returns 401/403, `RAPIDAPI_KEY` is missing or not subscribed to `booking-com15`.
Tell the user rather than guessing.

## Traveler preferences

Before planning, check for a preferences file and honor it. Lookup order (first hit wins):

1. The file at `$TRAVEL_PLANNING_PREFS`, if that env var is set
2. `./travel-preferences.local.md` in the current project
3. `~/.config/travel-planning/preferences.md`

It holds things like home airport/city, currency, companion and room rules (e.g.
"traveling with my partner → one double room, `adults=2`"), loyalty programs, cabin-bag
needs, and budget norms. See `travel-preferences.example.md` in the plugin root for the
shape. No file → no problem; use the defaults below and offer `/travel-setup` to create one.

## Flights — SerpApi `google_flights`

Always source the key from the environment; never inline it.

```bash
curl -s "https://serpapi.com/search.json?engine=google_flights\
&departure_id=AMS&arrival_id=LIS\
&outbound_date=2027-03-10&type=2\
&currency=EUR&hl=en&api_key=$SERPAPI_API_KEY"
```

- `departure_id` / `arrival_id`: IATA airport or city codes.
- `outbound_date` (and `return_date` for round trips), ISO `YYYY-MM-DD`.
- `type`: `1` round trip (needs `return_date`), `2` one way, `3` multi-city.
- `currency`, `hl`, optional `travel_class` (1 economy … 4 first), `adults`, `stops`.
- Response: `best_flights`, `other_flights`, `price_insights`. Sort by `price`; report
  airline, total duration, stops, price, and the `price_insights` typical range / level.

## Hotels — SerpApi `google_hotels`

```bash
curl -s "https://serpapi.com/search.json?engine=google_hotels\
&q=Lisbon+near+Baixa\
&check_in_date=2027-03-10&check_out_date=2027-03-13\
&adults=2&currency=EUR&hl=en&api_key=$SERPAPI_API_KEY"
```

- `q`: free-text area/landmark. `check_in_date` / `check_out_date` are **required**.
- `adults`, optional `children`, `sort_by`, `max_price`, `rating`, `hotel_class`.
- Response: `properties[]` with `name`, `rate_per_night`, `total_rate`, `gps_coordinates`,
  `overall_rating`, `amenities`, `link`. Report name, nightly + total price, rating, location.

## Hotels — Booking.com (RapidAPI `booking-com15`)

Use for real Booking.com inventory + bookable links. Two-step, free tier = 50 calls/mo.
Both calls need headers `x-rapidapi-host: booking-com15.p.rapidapi.com` and
`x-rapidapi-key: $RAPIDAPI_KEY`. Source the key from the environment; never inline it.

```bash
# 1) Resolve the destination to a dest_id + search_type
curl -s "https://booking-com15.p.rapidapi.com/api/v1/hotels/searchDestination?query=Lisbon" \
  -H "x-rapidapi-host: booking-com15.p.rapidapi.com" -H "x-rapidapi-key: $RAPIDAPI_KEY"
# -> data[]: pick the entry you want (dest_type city/district/airport); note dest_id + search_type.

# 2) Search hotels (UPPERCASE the search_type, e.g. CITY)
curl -s "https://booking-com15.p.rapidapi.com/api/v1/hotels/searchHotels\
?dest_id=-2167973&search_type=CITY\
&arrival_date=2027-03-10&departure_date=2027-03-13\
&adults=2&room_qty=1&page_number=1&currency_code=EUR&languagecode=en-us&units=metric" \
  -H "x-rapidapi-host: booking-com15.p.rapidapi.com" -H "x-rapidapi-key: $RAPIDAPI_KEY"
```

- Required: `dest_id`, `search_type` (UPPERCASE), `arrival_date`, `departure_date`.
- `adults`, `room_qty` (honor the preferences file — e.g. couples usually want one shared
  double room, not two singles), optional `children_age`, `price_min`/`price_max`,
  `sort_by`, `categories_filter`.
- Response: `data.hotels[].property` — `name`, `priceBreakdown.grossPrice.value` (total stay),
  `reviewScore`, `reviewScoreWord`, `latitude`/`longitude`, photos. Report name, total price,
  score, and area.
- **Booking links**: never construct a property URL by hand — you'd fabricate it. Either
  spend 1 extra call on `/api/v1/hotels/getHotelDetails?hotel_id=...&arrival_date=...&departure_date=...`
  and hand over its `url` field, or give a prefilled search link you can build safely:
  `https://www.booking.com/searchresults.html?ss=<hotel name, URL-encoded>&checkin=YYYY-MM-DD&checkout=YYYY-MM-DD&group_adults=N`.
- The same subscription also exposes Flights, Car Rental, Taxi, and Attraction endpoints
  under `/api/v1/<category>/...` if a trip needs them — but mind the 50/mo cap.

## Airbnb — bundled MCP

- `airbnb_search` — params: `location`, `checkin`, `checkout`, `adults`, optional
  `children`, `minPrice`, `maxPrice`, `placeId`. Returns listings with price + URL.
  **Always qualify `location` with region/country** ("Lisbon, Portugal", not "Lisbon") —
  bare city names get geocoded ambiguously (there is a Lisbon in Iowa). Sanity-check the
  returned `searchUrl` coordinates match the intended city before trusting results.
- `airbnb_listing_details` — params: `id` (listing id from search), plus the dates/guests,
  for amenities, house rules, and exact pricing.

## Routes, distances, places — Google APIs (curl)

Current-generation Google APIs, all keyed by `GOOGLE_MAPS_API_KEY`. POST bodies are
JSON; the `X-Goog-FieldMask` header is **required** on Routes/Places calls (request
only the fields you need — it's also what you're billed on).

**Directions — Routes API `computeRoutes`:**

```bash
curl -s -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
  -H "Content-Type: application/json" -H "X-Goog-Api-Key: $GOOGLE_MAPS_API_KEY" \
  -H "X-Goog-FieldMask: routes.duration,routes.distanceMeters,routes.legs.steps.transitDetails" \
  -d '{"origin":{"address":"Lisbon Airport"},"destination":{"address":"Baixa, Lisbon"},"travelMode":"TRANSIT"}'
```

- `travelMode`: `DRIVE`, `WALK`, `BICYCLE`, `TRANSIT`, `TWO_WHEELER`. For `DRIVE` you may
  add `"routingPreference":"TRAFFIC_AWARE"` and `"departureTime":"<RFC3339 UTC>"`.
- Drop `routes.legs.steps.transitDetails` from the mask for non-transit queries.

**Compare many origins/destinations (e.g. hotels by commute) — `computeRouteMatrix`:**

```bash
curl -s -X POST "https://routes.googleapis.com/distanceMatrix/v2:computeRouteMatrix" \
  -H "Content-Type: application/json" -H "X-Goog-Api-Key: $GOOGLE_MAPS_API_KEY" \
  -H "X-Goog-FieldMask: originIndex,destinationIndex,duration,distanceMeters,condition" \
  -d '{"origins":[{"waypoint":{"address":"Hotel A, Lisbon"}},{"waypoint":{"address":"Hotel B, Lisbon"}}],
       "destinations":[{"waypoint":{"address":"Baixa, Lisbon"}}],"travelMode":"WALK"}'
```

**POIs / "what's nearby" — Places API (New) `searchText`:**

```bash
curl -s -X POST "https://places.googleapis.com/v1/places:searchText" \
  -H "Content-Type: application/json" -H "X-Goog-Api-Key: $GOOGLE_MAPS_API_KEY" \
  -H "X-Goog-FieldMask: places.displayName,places.formattedAddress,places.rating,places.location,places.googleMapsUri" \
  -d '{"textQuery":"supermarket near Baixa, Lisbon","pageSize":5}'
```

**Address ↔ coordinates — Geocoding API (GET):**

```bash
curl -s "https://maps.googleapis.com/maps/api/geocode/json?address=Baixa%2C+Lisbon&key=$GOOGLE_MAPS_API_KEY"
```

The key's Cloud project must have **Routes API**, **Places API (New)**, and
**Geocoding API** enabled (all current products, enableable on any project — unlike
the legacy Directions/Distance Matrix/Places APIs, which new projects can't enable).

## Planning workflow

1. **Clarify only what blocks planning**: origin, destination, dates (or flexibility),
   trip purpose, budget, and where they need to be. Pick reasonable defaults and state
   them rather than over-asking.
2. **Flights** — search; present the best 3–4 by price/duration/stops with the typical
   price range so they know if it's a good deal.
3. **Stay** — search Google Hotels *and* Airbnb near where they need to be; compare a
   few on price, rating, and distance to the key location (use `computeRouteMatrix`).
   When the user wants real bookable hotels or a Booking.com link, also pull Booking.com
   inventory (mind its 50/mo cap — use it deliberately, not as the default first look).
4. **Ground logistics** — airport→stay and stay→destination routes with `computeRoutes`.
5. **Summarize** as a clean itinerary: flights, recommended stay (with link), and getting
   around. Surface trade-offs (cheaper-but-longer flight, farther-but-nicer hotel); don't
   silently pick.

## Defaults & rules

- **Currency**: use the preferences file; if none, infer from the user's context (route,
  locale) and always show the currency code.
- **Companions & rooms**: honor the preferences file (e.g. a couple traveling together →
  one shared double room, `adults=2`, `room_qty=1` — not two rooms).
- **Never book or pay anything** — this skill plans and recommends only. Present links and
  stop for the user to book.
- Verify dates are real and in the future; flag weekend/holiday timing if it affects price.
