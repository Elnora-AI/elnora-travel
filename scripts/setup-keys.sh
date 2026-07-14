#!/usr/bin/env bash
# Guided API-key setup for the travel-planning plugin (macOS / Linux).
#
#   scripts/setup-keys.sh            interactive: prompt, validate, save
#   scripts/setup-keys.sh --status   report which keys are set and working, no prompts
#
# Keys are saved as export lines in ~/.config/travel-planning/env (chmod 600).
# The plan-trip skill sources that file before every curl call. The script also
# offers to add one source line to your shell rc so the keys are available in
# any shell.

set -u
umask 077

ENV_DIR="$HOME/.config/travel-planning"
ENV_FILE="$ENV_DIR/env"
SOURCE_LINE='[ -f ~/.config/travel-planning/env ] && . ~/.config/travel-planning/env  # travel-planning plugin keys'

# Load anything previously saved so --status and re-runs see it.
# shellcheck source=/dev/null
[ -f "$ENV_FILE" ] && . "$ENV_FILE"

say() { printf '%s\n' "$*"; }

validate_serpapi() {
  curl -sf --max-time 15 "https://serpapi.com/account.json?api_key=$1" 2>/dev/null \
    | grep -q '"account_email"'
}

# Validates the two APIs the plugin actually depends on: Geocoding (GET) and the
# Routes API (POST computeRoutes). Both are current-generation and enableable on
# any Google Cloud project. Passing geocode alone is NOT enough — hence both.
validate_maps() {
  curl -sf --max-time 15 "https://maps.googleapis.com/maps/api/geocode/json?address=Paris&key=$1" 2>/dev/null \
    | grep -q '"status" *: *"OK"' || return 1
  curl -sf --max-time 15 -X POST "https://routes.googleapis.com/directions/v2:computeRoutes" \
    -H "Content-Type: application/json" -H "X-Goog-Api-Key: $1" \
    -H "X-Goog-FieldMask: routes.duration" \
    -d '{"origin":{"address":"Paris, France"},"destination":{"address":"Versailles, France"},"travelMode":"DRIVE"}' \
    2>/dev/null | grep -q '"duration"'
}

status_line() { # name, value, validator ("" = skip validation)
  local name="$1" value="$2" validator="$3"
  if [ -z "$value" ]; then
    say "  $name: not set"
  elif [ -z "$validator" ]; then
    say "  $name: set (not validated)"
  elif "$validator" "$value"; then
    say "  $name: set and working"
  else
    say "  $name: set but NOT working (bad key, or API not enabled)"
  fi
}

maps_status_line() { # value — reports Geocoding and Routes separately
  local value="$1"
  if [ -z "$value" ]; then
    say "  GOOGLE_MAPS_API_KEY (routes + places): not set"
  elif validate_maps "$value"; then
    say "  GOOGLE_MAPS_API_KEY (routes + places): set and working (Geocoding + Routes)"
  elif curl -sf --max-time 15 "https://maps.googleapis.com/maps/api/geocode/json?address=Paris&key=$value" 2>/dev/null | grep -q '"status" *: *"OK"'; then
    say "  GOOGLE_MAPS_API_KEY (routes + places): key valid (Geocoding) but Routes API NOT enabled — routes/commute features will fail. Enable 'Routes API' and 'Places API (New)' in Google Cloud Console."
  else
    say "  GOOGLE_MAPS_API_KEY (routes + places): set but NOT working (bad key, or Geocoding API not enabled)"
  fi
}

if [ "${1:-}" = "--status" ]; then
  say "travel-planning key status:"
  status_line "SERPAPI_API_KEY   (flights + hotels)" "${SERPAPI_API_KEY:-}" validate_serpapi
  maps_status_line "${GOOGLE_MAPS_API_KEY:-}"
  # Deliberately NOT validated here: each check burns 1 of the 50/month calls.
  status_line "RAPIDAPI_KEY      (Booking.com)" "${RAPIDAPI_KEY:-}" ""
  say "  Airbnb search: always available (no key)."
  exit 0
fi

save_key() { # varname, value (already charset-validated; quoted anyway for defense)
  mkdir -p "$ENV_DIR"
  touch "$ENV_FILE"
  chmod 600 "$ENV_FILE"
  grep -v "^export $1=" "$ENV_FILE" > "$ENV_FILE.tmp" 2>/dev/null || true
  printf "export %s='%s'\n" "$1" "$2" >> "$ENV_FILE.tmp"
  mv "$ENV_FILE.tmp" "$ENV_FILE"
  chmod 600 "$ENV_FILE"
}

prompt_key() { # varname, label, help, validator ("" = none), validate_note
  local var="$1" label="$2" help="$3" validator="$4" note="${5:-}"
  local current; eval "current=\${$var:-}"
  say ""
  say "== $label =="
  say "$help"
  if [ -n "$current" ]; then
    say "Already set. Press Enter to keep it, or paste a new key to replace (input hidden)."
  else
    say "Paste your key (input hidden; or press Enter to skip):"
  fi
  local key; IFS= read -rs key; say ""
  # Strip whitespace/CR (sloppy clipboards) — no valid key contains any.
  key=$(printf '%s' "$key" | tr -d '[:space:]\r')
  if [ -z "$key" ]; then
    if [ -n "$current" ]; then say "Kept existing $var."; else say "Skipped."; fi
    return 0
  fi
  # All three services' keys are [A-Za-z0-9_-]. Reject anything else — it would
  # be wrong anyway, and this keeps the sourced env file free of shell metacharacters.
  case "$key" in
    *[!A-Za-z0-9_-]*)
      say "That doesn't look like a valid key (unexpected characters). Not saved — rerun to try again."
      return 0 ;;
  esac
  if [ -n "$validator" ]; then
    say "Validating..."
    if "$validator" "$key"; then
      say "Key works."
    else
      say "WARNING: validation FAILED (bad key, or the API isn't enabled). Saving anyway — rerun to fix."
    fi
  elif [ -n "$note" ]; then
    say "$note"
  fi
  save_key "$var" "$key"
  eval "$var=\$key"
  say "Saved to $ENV_FILE."
}

say "travel-planning key setup. All three keys have free tiers; skip any — the plugin"
say "degrades gracefully (Airbnb search needs no key at all)."

prompt_key SERPAPI_API_KEY \
  "SERPAPI_API_KEY — live flights + hotel prices (Google Flights / Google Hotels)" \
  "Free: 250 searches/month. Sign up and copy the key at https://serpapi.com/manage-api-key" \
  validate_serpapi

prompt_key GOOGLE_MAPS_API_KEY \
  "GOOGLE_MAPS_API_KEY — routes, distances, commute comparison, places" \
  "Create an API key in Google Cloud Console (https://console.cloud.google.com/google/maps-apis)
and enable: Routes API, Places API (New), Geocoding API. Restrict the key to those APIs.
(These are the current-generation APIs — the legacy Directions/Distance Matrix/Places
APIs can't be enabled on new projects.)" \
  validate_maps

prompt_key RAPIDAPI_KEY \
  "RAPIDAPI_KEY — real Booking.com hotel inventory + bookable links (optional)" \
  "Free: 50 requests/month (hard cap). Sign up at https://rapidapi.com, subscribe to the
'booking-com15' API (Basic plan, no card), copy your app key from the API playground." \
  "" \
  "Not validated automatically — a test call would burn 1 of your 50 monthly requests."

if [ -f "$ENV_FILE" ]; then
  say ""
  RC_FILE="$HOME/.bashrc"
  case "${SHELL:-}" in */zsh) RC_FILE="$HOME/.zshrc" ;; esac
  if [ -f "$RC_FILE" ] && grep -qF "travel-planning plugin keys" "$RC_FILE"; then
    say "Your shell rc already sources the key file."
  else
    say "Optional: make the keys available in every shell (the plan-trip skill already"
    say "sources the key file itself). Add this line to $RC_FILE? [y/N]"
    say "  $SOURCE_LINE"
    IFS= read -r yn
    case "$yn" in
      [Yy]*) printf '\n%s\n' "$SOURCE_LINE" >> "$RC_FILE"; say "Added." ;;
      *) say "Skipped. The plugin still works — its skill sources $ENV_FILE directly." ;;
    esac
  fi
  say ""
  say "Done. If you added the rc line, open a new terminal (or 'source $RC_FILE')."
  say "Check anytime with: setup-keys.sh --status"
fi
