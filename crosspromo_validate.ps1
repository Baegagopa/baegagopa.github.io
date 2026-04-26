param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'
$errors = New-Object System.Collections.Generic.List[string]

function Add-ValidationError {
    param([string]$Message)
    $script:errors.Add($Message)
}

function Is-NonEmptyString {
    param($Value)
    return ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value))
}

function Test-HttpsUrl {
    param($Value)
    if (-not (Is-NonEmptyString $Value)) { return $false }
    try {
        $uri = [Uri]$Value
        return $uri.IsAbsoluteUri -and $uri.Scheme -eq 'https'
    }
    catch {
        return $false
    }
}

function Test-NonNegativeNumber {
    param($Value)
    return ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal]) -and $Value -ge 0
}

if (-not (Test-Path -LiteralPath $Path)) {
    Add-ValidationError "File not found: $Path"
}
else {
    try {
        $raw = Get-Content -LiteralPath $Path -Raw -Encoding UTF8
        $json = $raw | ConvertFrom-Json
    }
    catch {
        Add-ValidationError "JSON parse failed: $($_.Exception.Message)"
    }
}

if ($errors.Count -eq 0) {
    foreach ($field in @('version', 'global_switch', 'cache_ttl_hours', 'display_rules', 'games')) {
        if (-not ($json.PSObject.Properties.Name -contains $field)) {
            Add-ValidationError "Missing root field: $field"
        }
    }

    if (-not (Test-NonNegativeNumber $json.version)) {
        Add-ValidationError 'version must be a non-negative number'
    }
    if (-not ($json.global_switch -is [bool])) {
        Add-ValidationError 'global_switch must be a boolean'
    }
    if (-not (Test-NonNegativeNumber $json.cache_ttl_hours)) {
        Add-ValidationError 'cache_ttl_hours must be a non-negative number'
    }

    if ($null -eq $json.display_rules) {
        Add-ValidationError 'display_rules is missing'
    }
    else {
        foreach ($field in @('max_daily_impressions', 'min_sessions_before_show', 'cooldown_between_promos_minutes')) {
            if (-not ($json.display_rules.PSObject.Properties.Name -contains $field) -or -not (Test-NonNegativeNumber $json.display_rules.$field)) {
                Add-ValidationError "display_rules.$field must be a non-negative number"
            }
        }
    }

    $games = @($json.games)
    if ($games.Count -eq 0) {
        Add-ValidationError 'games must contain at least one entry'
    }

    foreach ($game in $games) {
        $gameId = if (Is-NonEmptyString $game.id) { $game.id } else { '<missing-id>' }

        foreach ($field in @('id', 'name', 'tagline', 'app_kind')) {
            if (-not (Is-NonEmptyString $game.$field)) {
                Add-ValidationError "Game $gameId has invalid field: $field"
            }
        }
        foreach ($field in @('enabled', 'is_featured', 'exclude_current_game')) {
            if (-not ($game.$field -is [bool])) {
                Add-ValidationError "Game $gameId has invalid boolean field: $field"
            }
        }
        if (-not (Test-NonNegativeNumber $game.priority)) {
            Add-ValidationError "Game $gameId has invalid priority"
        }
        foreach ($urlField in @('icon_url', 'banner_url')) {
            if (-not (Test-HttpsUrl $game.$urlField)) {
                Add-ValidationError "Game $gameId has invalid HTTPS URL in $urlField"
            }
        }

        $targetPlatforms = @($game.target_platforms)
        if ($targetPlatforms.Count -eq 0) {
            Add-ValidationError "Game $gameId must define target_platforms"
        }
        if ($null -eq $game.platforms) {
            Add-ValidationError "Game $gameId must define platforms"
        }
        elseif ($targetPlatforms -contains 'android') {
            if ($null -eq $game.platforms.android) {
                Add-ValidationError "Game $gameId must define platforms.android"
            }
            else {
                if (-not (Is-NonEmptyString $game.platforms.android.applicationId)) {
                    Add-ValidationError "Game $gameId has invalid platforms.android.applicationId"
                }
                if (-not (Test-HttpsUrl $game.platforms.android.storeUrl)) {
                    Add-ValidationError "Game $gameId has invalid platforms.android.storeUrl"
                }
            }
        }

        if ($null -eq $game.localized_content -or $null -eq $game.localized_content._items) {
            Add-ValidationError "Game $gameId must define localized_content._items"
        }
        else {
            $items = @($game.localized_content._items)
            if ($items.Count -eq 0) {
                Add-ValidationError "Game $gameId must contain at least one localized entry"
            }
            foreach ($item in $items) {
                if (-not (Is-NonEmptyString $item.key)) {
                    Add-ValidationError "Game $gameId has localized entry with invalid key"
                    continue
                }
                if ($null -eq $item.value) {
                    Add-ValidationError "Game $gameId locale $($item.key) is missing value"
                    continue
                }
                foreach ($field in @('name', 'tagline')) {
                    if (-not (Is-NonEmptyString $item.value.$field)) {
                        Add-ValidationError "Game $gameId locale $($item.key) has invalid field: $field"
                    }
                }
            }
        }
    }
}

if ($errors.Count -gt 0) {
    Write-Host '[ERROR] CrossPromo validation failed:' -ForegroundColor Red
    foreach ($err in $errors) {
        Write-Host " - $err" -ForegroundColor Red
    }
    exit 1
}

Write-Host "[OK] CrossPromo validation passed: $Path" -ForegroundColor Green
exit 0
