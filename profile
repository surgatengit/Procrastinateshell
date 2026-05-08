# ==============================
# PowerShell Profile
# Anti-Procrastinator Candidate Environment
# ==============================

# --- Oh My Posh ---
$env:POSH_GIT_ENABLED = $true

oh-my-posh init pwsh --config "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\pentescatination.omp.json" | Invoke-Expression


# --- Modules ---
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module CompletionPredictor -ErrorAction SilentlyContinue


# --- PSReadLine / Predictions ---
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows


# --- Useful helper functions ---
function touch {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (Test-Path $Path) {
        (Get-Item $Path).LastWriteTime = Get-Date
    } else {
        New-Item -ItemType File -Path $Path | Out-Null
    }
}

function Get-PublicNetworkInfo {
    try {
        $trace = Invoke-RestMethod -Uri "https://1.1.1.1/cdn-cgi/trace" -TimeoutSec 2

        $data = @{}

        foreach ($line in ($trace -split "`n")) {
            if ($line -match "^(.*?)=(.*)$") {
                $data[$matches[1]] = $matches[2].Trim()
            }
        }

        $ip = if ($data.ContainsKey("ip")) { $data["ip"] } else { "IP desconocida" }
        $country = if ($data.ContainsKey("loc")) { $data["loc"] } else { "??" }
        $colo = if ($data.ContainsKey("colo")) { $data["colo"] } else { "???" }
        $warp = if ($data.ContainsKey("warp")) { $data["warp"] } else { "unknown" }

        $vpnHint = switch ($warp) {
            "on"      { "Cloudflare WARP: ON" }
            "plus"    { "Cloudflare WARP+: ON" }
            "off"     { "Cloudflare WARP: off" }
            default   { "Cloudflare WARP: unknown" }
        }

        return [PSCustomObject]@{
            IP      = $ip
            Country = $country
            Colo    = $colo
            Warp    = $warp
            Hint    = $vpnHint
        }
    }
    catch {
        return [PSCustomObject]@{
            IP      = "IP no disponible"
            Country = "??"
            Colo    = "???"
            Warp    = "unknown"
            Hint    = "Sin conexión o timeout"
        }
    }
}


# --- Aliases ---
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String


# --- Welcome Banner ---
Write-Host ""
Write-Host "              Welcome to the Anti-Procrastinator Candidate PowerShell Environment." -ForegroundColor Cyan
Write-Host ""

Write-Host "Recuerda:" -ForegroundColor Yellow
Write-Host "F1, al final de un cmdlet o parametro --> Muestra la Ayuda."
Write-Host "Ctrl + Espacio despues del -          --> Muestra parametros seleccionables."
Write-Host "Alt + a                               --> Desplazarse por los argumentos."
Write-Host "Alt + h                               --> Ayuda del parametro."
Write-Host ""

$net = Get-PublicNetworkInfo

Write-Host "Red publica:" -ForegroundColor Yellow
Write-Host "IP:      $($net.IP)" -ForegroundColor Red
Write-Host "Pais:    $($net.Country)    Cloudflare Colo: $($net.Colo)    $($net.Hint)" -ForegroundColor DarkGray
Write-Host "               Alianza Rebelde  " -ForegroundColor Red
Write-Host ""
