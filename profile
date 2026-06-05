# ==============================
# PowerShell Profile
# Anti-Procrastinator Candidate Environment
# Requiere PowerShell 7+ (uso del operador ?? )
# ==============================

# --- Oh My Posh ---
oh-my-posh init pwsh --config "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\pentescatination.omp.json" | Invoke-Expression

# --- Modules ---
Import-Module Terminal-Icons -ErrorAction SilentlyContinue
Import-Module CompletionPredictor -ErrorAction SilentlyContinue

# --- PSReadLine / Predictions ---
# Las predicciones ya vienen activadas en PowerShell moderno, pero por defecto
# con origen 'History' y vista 'InlineView'. Aqui las subo a:
#   - HistoryAndPlugin: usa ademas el predictor CompletionPredictor importado arriba.
#   - ListView: vista en lista en vez de en linea.
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView

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
    <#
        Lee el endpoint /cdn-cgi/trace de Cloudflare y devuelve los campos
        relevantes de seguridad de la conexion.

        IMPORTANTE: esto sale por la pila TLS de .NET / Windows (Schannel), NO
        por Firefox. Son stacks distintos: si ves sni=plaintext aqui aunque tu
        navegador haga ECH, es porque Schannel todavia no negocia ECH. El banner
        refleja la postura REAL de tu sistema, que es lo que interesa medir.
    #>
    [CmdletBinding()]
    param(
        [string]$TraceUri = "https://crypto.cloudflare.com/cdn-cgi/trace",
        [int]$TimeoutSec  = 4
    )
    try {
        $raw = Invoke-RestMethod -Uri $TraceUri -TimeoutSec $TimeoutSec -ErrorAction Stop
        $data = @{}
        foreach ($line in ($raw -split "`n")) {
            if ($line -match "^(.*?)=(.*)$") { $data[$matches[1]] = $matches[2].Trim() }
        }

        $kex = $data['kex'] ?? 'N/D'
        $pq  = [bool]($kex -match 'MLKEM|Kyber')   # intercambio de claves post-cuantico

        $sni = $data['sni'] ?? 'N/D'
        $ech = switch ($sni) {
            'encrypted' { 'ECH activo (SNI cifrado)' }
            'plaintext' { 'sin ECH (SNI en claro)' }
            'off'       { 'sin SNI (conexion por IP)' }
            default     { 'desconocido' }
        }

        [PSCustomObject][ordered]@{
            IP          = $data['ip']   ?? 'desconocida'
            Country     = $data['loc']  ?? '??'
            Colo        = $data['colo'] ?? '???'
            Warp        = $data['warp'] ?? 'unknown'
            Tls         = $data['tls']  ?? 'N/D'
            Kex         = $kex
            PostQuantum = $pq
            Sni         = $sni
            Ech         = $ech
            Gateway     = $data['gateway'] ?? 'off'
            Ok          = $true
        }
    }
    catch {
        [PSCustomObject][ordered]@{
            IP = ''; Country = ''; Colo = ''; Warp = ''; Tls = ''; Kex = ''
            PostQuantum = $false; Sni = ''; Ech = 'Sin conexion o timeout'
            Gateway = ''; Ok = $false
        }
    }
}

function Get-DnsEncryptionStatus {
    <#
        Best-effort en Windows 11: comprueba el DNS del adaptador activo y si
        esta configurado como cifrado (DoH). Guardado con try/catch para que
        nunca rompa el arranque del perfil.
    #>
    try {
        $primary = Get-DnsClientServerAddress -AddressFamily IPv4 -ErrorAction Stop |
                   Where-Object { $_.ServerAddresses.Count -gt 0 } |
                   Select-Object -First 1
        $servers = @($primary.ServerAddresses)

        $dohList = @()
        try { $dohList = @((Get-DnsClientDohServerAddress -ErrorAction Stop).ServerAddress) } catch {}

        $encrypted = $false
        foreach ($s in $servers) { if ($dohList -contains $s) { $encrypted = $true } }

        [PSCustomObject]@{
            Servers   = if ($servers) { $servers -join ', ' } else { 'N/D' }
            Encrypted = $encrypted
        }
    }
    catch {
        [PSCustomObject]@{ Servers = 'N/D'; Encrypted = $false }
    }
}

# --- Aliases ---
Set-Alias ll Get-ChildItem
Set-Alias grep Select-String   # nota: la sintaxis de Select-String no es identica a grep

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
$dns = Get-DnsEncryptionStatus

Write-Host "Red publica:" -ForegroundColor Yellow
if ($net.Ok) {
    Write-Host "IP:      $($net.IP)" -ForegroundColor Red
    Write-Host "Pais:    $($net.Country)    Colo: $($net.Colo)    WARP: $($net.Warp)" -ForegroundColor DarkGray

    # TLS / intercambio de claves (verde si negocia post-cuantico)
    $kexColor = if ($net.PostQuantum) { 'Green' } else { 'DarkYellow' }
    $kexTag   = if ($net.PostQuantum) { 'post-cuantico' } else { 'clasico' }
    Write-Host "TLS:     $($net.Tls)    Kex: $($net.Kex) [$kexTag]" -ForegroundColor $kexColor

    # SNI / ECH (verde si el sistema cifra el SNI)
    $sniColor = switch ($net.Sni) { 'encrypted' { 'Green' } 'plaintext' { 'DarkYellow' } default { 'DarkGray' } }
    Write-Host "SNI:     $($net.Sni) -> $($net.Ech)" -ForegroundColor $sniColor

    # Estado de cifrado del DNS del sistema
    $dnsColor = if ($dns.Encrypted) { 'Green' } else { 'DarkYellow' }
    $dnsTag   = if ($dns.Encrypted) { 'cifrado (DoH)' } else { 'EN CLARO' }
    Write-Host "DNS:     $($dns.Servers) [$dnsTag]" -ForegroundColor $dnsColor
}
else {
    Write-Host $net.Ech -ForegroundColor DarkGray
}
Write-Host "               Alianza Rebelde    " -ForegroundColor Red
Write-Host ""
