# Mejorado directo pasado por IA
# Script designed to be run after a fresh Windows installation or format. It installs essential programs and what might be the best shell configuration ever created: ProcrastinateShell.
# Para lanzarlo desde el sistema, tenemos dos opciones, quitar la marca de internet, y luego cambiar la politica para el usuario actual, o hacer un bypass del script.
# Unblock-File -Path .\setup.ps1
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# o usar para ejecutar sin cambiar la politica
# powershell -ExecutionPolicy Bypass -File .\setup.ps1

# -------------------------
# Helpers: UX + Admin + Download
# -------------------------

function Write-Step {
    param(
        [Parameter(Mandatory)] [string] $Message,
        [ValidateSet("Info","Ok","Warn","Err","Step")] [string] $Level = "Info"
    )

    switch ($Level) {
        "Step" { Write-Host "▶ $Message" -ForegroundColor Cyan }
        "Info" { Write-Host "• $Message" -ForegroundColor Gray }
        "Ok"   { Write-Host "✅ $Message" -ForegroundColor Green }
        "Warn" { Write-Host "⚠️  $Message" -ForegroundColor Yellow }
        "Err"  { Write-Host "❌ $Message" -ForegroundColor Red }
    }
}

function Invoke-Step {
    param(
        [Parameter(Mandatory)] [string] $Title,
        [Parameter(Mandatory)] [scriptblock] $Action,
        [switch] $Fatal
    )
    Write-Step -Message $Title -Level Step
    $sw = [Diagnostics.Stopwatch]::StartNew()
    try {
        & $Action
        $sw.Stop()
        Write-Step -Message ("{0} (en {1:N1}s)" -f $Title, $sw.Elapsed.TotalSeconds) -Level Ok
        return $true
    } catch {
        $sw.Stop()
        Write-Step -Message ("{0} (falló en {1:N1}s): {2}" -f $Title, $sw.Elapsed.TotalSeconds, $_) -Level Err
        if ($Fatal) { throw }
        return $false
    }
}

# Function to check if script is running as administrator
function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Ensure TLS 1.2 for older Win/PS 5.1 environments
function Use-Tls12 {
    try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}
}

# Fast/clean download for PowerShell 5.1: BITS -> curl.exe -> Invoke-WebRequest (no noisy progress)
function Download-FileFast {
    param(
        [Parameter(Mandatory)] [string] $Uri,
        [Parameter(Mandatory)] [string] $OutFile
    )

    Use-Tls12

    $pp = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'  # avoids slow/byte-by-byte progress in PS 5.1
    try {
        # 1) BITS (best UX / reliability on Windows)
        try {
            Start-BitsTransfer -Source $Uri -Destination $OutFile -ErrorAction Stop
            return
        } catch {}

        # 2) curl.exe (usually present on Win10/11)
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            & $curl.Source -L --retry 3 --retry-delay 2 -# -o $OutFile $Uri
            if ($LASTEXITCODE -ne 0) { throw "curl.exe falló con código $LASTEXITCODE" }
            return
        }

        # 3) Last resort
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing -ErrorAction Stop
    }
    finally {
        $ProgressPreference = $pp
    }
}

# Check for elevated permissions
if (-not (Test-Admin)) {
    Write-Step -Message "This script requires elevated privileges (Administrator). Please run as Administrator." -Level Err
    exit
}

Write-Step -Message "Inicio de setup post-instalación" -Level Step

# -------------------------
# Winget bootstrap / update
# -------------------------

Invoke-Step -Title "Comprobando/actualizando Winget" -Fatal -Action {
    $repo = "microsoft/winget-cli"
    $urlApi = "https://api.github.com/repos/$repo/releases/latest"

    Use-Tls12
    $headers = @{
        "User-Agent" = "setup.ps1"
        "Accept"     = "application/vnd.github+json"
    }

    $latestRelease = Invoke-RestMethod -Uri $urlApi -Headers $headers
    $latestVersionTag = $latestRelease.tag_name.Replace('v', '').Trim()
    $requiredVersion = [version]$latestVersionTag

    $downloadUrl = ($latestRelease.assets |
        Where-Object { $_.name -like "*.msixbundle" } |
        Select-Object -First 1
    ).browser_download_url

    if (-not $downloadUrl) {
        throw "No se encontró un asset .msixbundle en el release latest."
    }

    $currentVersion = [version]"0.0.0.0"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $currentVersion = [version](winget -v).Replace('v', '').Trim()
    }

    if ($currentVersion -ge $requiredVersion) {
        Write-Step -Message "Winget ya está actualizado ($currentVersion)." -Level Ok
        return
    }

    Write-Step -Message "Winget desactualizado ($currentVersion). Objetivo: $requiredVersion" -Level Warn

    $destination = Join-Path $env:TEMP "Winget_Update_$($requiredVersion).msixbundle"

    Invoke-Step -Title "Descargando Winget (.msixbundle)" -Fatal -Action {
        Download-FileFast -Uri $downloadUrl -OutFile $destination
    } | Out-Null

    Invoke-Step -Title "Cerrando procesos bloqueantes (WinGet/AppInstaller)" -Action {
        Get-Process -Name "WinGet", "AppInstaller" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2
    } | Out-Null

    Invoke-Step -Title "Instalando paquete Winget" -Fatal -Action {
        Add-AppxPackage -Path $destination -ForceApplicationShutdown -ErrorAction Stop
    } | Out-Null

    Remove-Item $destination -Force -ErrorAction SilentlyContinue
    Write-Step -Message "Winget actualizado a $requiredVersion" -Level Ok
} | Out-Null

# -------------------------
# Ensure PowerShell 7+
# -------------------------

function Is-PowerShell7 {
    return $PSVersionTable.PSVersion.Major -ge 7
}

if (-not (Is-PowerShell7)) {
    Invoke-Step -Title "Instalando PowerShell 7" -Fatal -Action {
        winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent *> $null
    } | Out-Null

    Write-Step -Message "Reabriendo este script en PowerShell 7..." -Level Warn
    Start-Sleep -Seconds 2

    $scriptPath = $PSCommandPath
    Start-Process "pwsh" -ArgumentList "-NoProfile -NoExit -File `"$scriptPath`""
    exit
} else {
    Write-Step -Message "PowerShell 7 ya está en ejecución." -Level Ok
}

# -------------------------
# Fonts detection helper
# -------------------------

function Is-FontInstalled {
    param ([string]$FontName)

    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    )

    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            $fonts = Get-ItemProperty -Path $path
            if ($fonts.PSObject.Properties.Name -like "*$FontName*") { return $true }
        }
    }
    return $false
}

# -------------------------
# Install Oh My Posh
# -------------------------

if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    Invoke-Step -Title "Instalando Oh My Posh" -Action {
        winget install JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements --silent *> $null
    } | Out-Null

    Write-Step -Message "Reiniciando script para cargar variables..." -Level Warn
    $scriptPath = $PSCommandPath
    Start-Process "pwsh" -ArgumentList "-NoProfile -File `"$scriptPath`""
    exit
} else {
    Write-Step -Message "Oh My Posh ya está instalado." -Level Ok
}

# -------------------------
# Install Nerd Fonts via OMP
# -------------------------

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $fuentes = @("Meslo", "Hack")

    foreach ($f in $fuentes) {
        if (-not (Is-FontInstalled -FontName "$f*Nerd Font")) {
            Invoke-Step -Title "Instalando fuente $f Nerd Font" -Action {
                $nombreFuente = $f.ToLower()
                oh-my-posh font install $nombreFuente
            } | Out-Null
        } else {
            Write-Step -Message "Fuente $f ya instalada. Saltando..." -Level Info
        }
    }
}

# -------------------------
# Windows Terminal settings.json font
# -------------------------

Invoke-Step -Title "Configurando fuente por defecto en Windows Terminal" -Fatal -Action {
    $terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    if (-not (Test-Path $terminalSettingsPath)) {
        throw "settings.json no encontrado. Asegúrate de que Windows Terminal está instalado y se ha abierto al menos una vez."
    }

    $settingsJson = Get-Content -Path $terminalSettingsPath -Raw | ConvertFrom-Json

    if (-not $settingsJson.profiles.defaults) { $settingsJson.profiles.defaults = @{} }
    if (-not $settingsJson.profiles.defaults.font) {
        $settingsJson.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{}
    }

    $settingsJson.profiles.defaults.font.face = "Hack Nerd Font"
    $settingsJson | ConvertTo-Json -Depth 100 | Set-Content -Path $terminalSettingsPath -Force
} | Out-Null

# -------------------------
# PowerShell profile edits
# -------------------------

Invoke-Step -Title "Actualizando perfil de PowerShell" -Fatal -Action {
    $profilePath = $PROFILE
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -Type File -Force | Out-Null
    }

    function Add-IfNotExists {
        param ([string]$path, [string]$line)
        $currentContent = Get-Content -Path $path -ErrorAction SilentlyContinue
        if ($currentContent -notcontains $line) { Add-Content -Path $path -Value $line }
    }

    Add-IfNotExists $profilePath 'oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/pentescatination.omp.json | Invoke-Expression'
    Add-IfNotExists $profilePath 'Import-Module -Name Terminal-Icons'
    Add-IfNotExists $profilePath 'Import-Module CompletionPredictor'
    Add-IfNotExists $profilePath '$env:POSH_GIT_ENABLED = $true'
    Add-IfNotExists $profilePath 'Set-PSReadLineOption -PredictionViewStyle ListView'
    Add-IfNotExists $profilePath 'Write-Host "                  Rebel Alliance " -ForegroundColor red'
    Add-IfNotExists $profilePath 'Write-Host "                  󱋌  " -NoNewline'
    Add-IfNotExists $profilePath 'Write-Host  (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() 󱋌'
} | Out-Null

# Set execution policy to Unrestricted for current user
Invoke-Step -Title "Ajustando ExecutionPolicy (CurrentUser -> Unrestricted)" -Action {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
} | Out-Null

# -------------------------
# Download custom OMP theme (fast download)
# -------------------------

if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    Invoke-Step -Title "Descargando tema personalizado de Oh My Posh" -Action {
        $themeDir  = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
        $themePath = Join-Path $themeDir "pentescatination.omp.json"

        if (-not (Test-Path $themeDir)) {
            New-Item -Path $themeDir -ItemType Directory -Force | Out-Null
        }

        $url = "https://raw.githubusercontent.com/surgatengit/Procrastinateshell/main/pentescatination.omp.json"
        Download-FileFast -Uri $url -OutFile $themePath
    } | Out-Null
} else {
    Write-Step -Message "Oh My Posh no encontrado, saltando descarga de tema." -Level Warn
}

# -------------------------
# Install PowerShell modules
# -------------------------

Invoke-Step -Title "Instalando módulo Terminal-Icons" -Action {
    Install-Module -Name Terminal-Icons -Force -ErrorAction Stop
} | Out-Null

Invoke-Step -Title "Instalando módulo CompletionPredictor" -Action {
    Install-Module -Name CompletionPredictor -Force -ErrorAction Stop
} | Out-Null

# -------------------------
# Winget app installer helper
# -------------------------

function Install-App {
    param(
        [string]$AppId,
        [string]$AppName,
        [int]$TimeoutMinutes = 20,
        [int]$HeartbeatSeconds = 30
    )

    $log = Join-Path $env:TEMP ("winget_{0}_{1:yyyyMMdd_HHmmss}.log" -f ($AppId -replace '[^a-zA-Z0-9\.-]', '_'), (Get-Date))

    Invoke-Step -Title "Instalando $AppName" -Action {

        $args = @(
            "install", "-e", "--id", $AppId,
            "--accept-package-agreements", "--accept-source-agreements",
            "--source", "winget",
            "--silent"
        )

        $p = Start-Process -FilePath "winget" -ArgumentList $args -PassThru -NoNewWindow `
            -RedirectStandardOutput $log -RedirectStandardError $log

        $deadline = (Get-Date).AddMinutes($TimeoutMinutes)

        while (-not $p.HasExited) {
            if ((Get-Date) -ge $deadline) {
                try { $p.Kill() } catch {}
                throw "Timeout ($TimeoutMinutes min). Revisa el log: $log"
            }

            # Heartbeat: indica que sigue vivo (sin ensuciar demasiado)
            Write-Step -Message ("{0}: sigue instalando... (PID {1})" -f $AppName, $p.Id) -Level Info
            Start-Sleep -Seconds $HeartbeatSeconds
        }

        if ($p.ExitCode -ne 0) {
            throw "Winget devolvió ExitCode $($p.ExitCode). Revisa el log: $log"
        }
    } | Out-Null
}

# Lista de aplicaciones a instalar (incluye Git en el mismo flujo)
$apps = @(
    @{ id = "Mozilla.Firefox.es-ES";               name = "Firefox" },
    @{ id = "Mobatek.MobaXterm";                  name = "MobaXterm" },
    @{ id = "Microsoft.PowerToys";                name = "PowerToys" },
    @{ id = "Microsoft.VisualStudioCode";         name = "Visual Studio Code" },
    @{ id = "OpenVPNTechnologies.OpenVPNConnect"; name = "OpenVPN Connect" },
    @{ id = "7zip.7zip";                          name = "7zip" },
    @{ id = "dnSpyEx.dnSpy";                      name = "dnSpyEX" },
    @{ id = "Obsidian.Obsidian";                  name = "Obsidian" },
    @{ id = "Git.Git";                            name = "Git" }
)

foreach ($app in $apps) {
    Install-App -AppId $app.id -AppName $app.name
}

# Install posh-git (if Git is installed)
if (Get-Command git -ErrorAction SilentlyContinue) {
    Invoke-Step -Title "Instalando módulo posh-git" -Action {
        Install-Module posh-git -Scope CurrentUser -Force -ErrorAction Stop
    } | Out-Null
} else {
    Write-Step -Message "Git no encontrado, saltando posh-git." -Level Warn
}

# -------------------------
# Update PowerShell Help
# -------------------------

Invoke-Step -Title "Actualizando ayuda de PowerShell (Update-Help)" -Action {
    Update-Help
} | Out-Null

Write-Step -Message "Script execution completed! Please reload PowerShell terminal!" -Level Ok
