# Guided API-key setup for the travel-planning plugin (Windows).
#
#   scripts/setup-keys.ps1           interactive: prompt, validate, save
#   scripts/setup-keys.ps1 -Status   report which keys are set and working, no prompts
#
# Keys are saved as per-user environment variables ([Environment]::SetEnvironmentVariable
# with User scope), so both the plan-trip curl calls and the Google Maps MCP server see
# them after you restart Claude Code.

param([switch]$Status)

$ErrorActionPreference = "Stop"

function Get-Key([string]$Name) {
    $v = [Environment]::GetEnvironmentVariable($Name, "User")
    if (-not $v) { $v = [Environment]::GetEnvironmentVariable($Name, "Process") }
    return $v
}

function Test-SerpApi([string]$Key) {
    try {
        $r = Invoke-RestMethod -TimeoutSec 15 -Uri "https://serpapi.com/account.json?api_key=$Key"
        return [bool]$r.account_email
    } catch { return $false }
}

function Test-Geocoding([string]$Key) {
    try {
        $r = Invoke-RestMethod -TimeoutSec 15 -Uri "https://maps.googleapis.com/maps/api/geocode/json?address=Paris&key=$Key"
        return $r.status -eq "OK"
    } catch { return $false }
}

function Test-Routes([string]$Key) {
    try {
        $body = '{"origin":{"address":"Paris, France"},"destination":{"address":"Versailles, France"},"travelMode":"DRIVE"}'
        $headers = @{ "X-Goog-Api-Key" = $Key; "X-Goog-FieldMask" = "routes.duration" }
        $r = Invoke-RestMethod -TimeoutSec 15 -Method Post -ContentType "application/json" `
            -Uri "https://routes.googleapis.com/directions/v2:computeRoutes" -Headers $headers -Body $body
        return [bool]$r.routes
    } catch { return $false }
}

# Both APIs the plugin depends on must work; geocode alone is not enough.
function Test-Maps([string]$Key) {
    return (Test-Geocoding $Key) -and (Test-Routes $Key)
}

function Save-Key([string]$Name, [string]$Value) {
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path "Env:$Name" -Value $Value
}

if ($Status) {
    Write-Host "travel-planning key status:"
    $serp = Get-Key "SERPAPI_API_KEY"
    if (-not $serp) { Write-Host "  SERPAPI_API_KEY   (flights + hotels): not set" }
    elseif (Test-SerpApi $serp) { Write-Host "  SERPAPI_API_KEY   (flights + hotels): set and working" }
    else { Write-Host "  SERPAPI_API_KEY   (flights + hotels): set but NOT working" }

    $maps = Get-Key "GOOGLE_MAPS_API_KEY"
    if (-not $maps) { Write-Host "  GOOGLE_MAPS_API_KEY (routes + places): not set" }
    elseif (Test-Maps $maps) { Write-Host "  GOOGLE_MAPS_API_KEY (routes + places): set and working (Geocoding + Routes)" }
    elseif (Test-Geocoding $maps) { Write-Host "  GOOGLE_MAPS_API_KEY (routes + places): key valid (Geocoding) but Routes API NOT enabled - routes/commute features will fail. Enable 'Routes API' and 'Places API (New)' in Google Cloud Console." }
    else { Write-Host "  GOOGLE_MAPS_API_KEY (routes + places): set but NOT working (bad key, or Geocoding API not enabled)" }

    # Deliberately NOT validated: each check burns 1 of the 50/month calls.
    $rapid = Get-Key "RAPIDAPI_KEY"
    if (-not $rapid) { Write-Host "  RAPIDAPI_KEY      (Booking.com): not set" }
    else { Write-Host "  RAPIDAPI_KEY      (Booking.com): set (not validated)" }

    Write-Host "  Airbnb search: always available (no key)."
    exit 0
}

function Prompt-Key {
    param([string]$Name, [string]$Label, [string]$Help, [scriptblock]$Validator, [string]$Note)
    Write-Host ""
    Write-Host "== $Label =="
    Write-Host $Help
    $current = Get-Key $Name
    if ($current) { Write-Host "Already set. Press Enter to keep it, or paste a new key to replace (input hidden)." }
    else { Write-Host "Paste your key (input hidden; or press Enter to skip):" }
    $secure = Read-Host -AsSecureString
    $bstr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try { $key = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr) }
    finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($bstr) }
    # Strip whitespace/CR (sloppy clipboards) — no valid key contains any.
    $key = ($key -replace '\s', '')
    if (-not $key) {
        if ($current) { Write-Host "Kept existing $Name." } else { Write-Host "Skipped." }
        return
    }
    # All three services' keys are [A-Za-z0-9_-]; anything else is a bad paste.
    if ($key -notmatch '^[A-Za-z0-9_-]{8,}$') {
        Write-Host "That doesn't look like a valid key (unexpected characters). Not saved - rerun to try again."
        return
    }
    if ($Validator) {
        Write-Host "Validating..."
        if (& $Validator $key) { Write-Host "Key works." }
        else { Write-Host "WARNING: validation FAILED (bad key, or the API isn't enabled). Saving anyway - rerun to fix." }
    } elseif ($Note) {
        Write-Host $Note
    }
    Save-Key $Name $key
    Write-Host "Saved as a per-user environment variable."
}

Write-Host "travel-planning key setup. All three keys have free tiers; skip any - the plugin"
Write-Host "degrades gracefully (Airbnb search needs no key at all)."

Prompt-Key -Name "SERPAPI_API_KEY" `
    -Label "SERPAPI_API_KEY - live flights + hotel prices (Google Flights / Google Hotels)" `
    -Help "Free: 250 searches/month. Sign up and copy the key at https://serpapi.com/manage-api-key" `
    -Validator ${function:Test-SerpApi}

Prompt-Key -Name "GOOGLE_MAPS_API_KEY" `
    -Label "GOOGLE_MAPS_API_KEY - routes, distances, commute comparison, places" `
    -Help "Create an API key in Google Cloud Console (https://console.cloud.google.com/google/maps-apis)`nand enable: Routes API, Places API (New), Geocoding API. Restrict the key to those APIs.`n(These are the current-generation APIs - the legacy Directions/Distance Matrix/Places`nAPIs can't be enabled on new projects.)" `
    -Validator ${function:Test-Maps}

Prompt-Key -Name "RAPIDAPI_KEY" `
    -Label "RAPIDAPI_KEY - real Booking.com hotel inventory + bookable links (optional)" `
    -Help "Free: 50 requests/month (hard cap). Sign up at https://rapidapi.com, subscribe to the`n'booking-com15' API (Basic plan, no card), copy your app key from the API playground." `
    -Note "Not validated automatically - a test call would burn 1 of your 50 monthly requests."

Write-Host ""
Write-Host "Done. Restart Claude Code so its tools see the new environment variables."
Write-Host "Check anytime with: setup-keys.ps1 -Status"
