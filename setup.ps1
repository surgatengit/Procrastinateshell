# Script designed to be run after a fresh Windows installation or format. It installs essential programs and what might be the best shell configuration ever created: ProcrastinateShell.
# Para lanzarlo desde el sistema, tenemos dos opciones, quitar la marca de internet, y luego cambiar la politica para el usuario actual, o hacer un bypass del script.
# Unblock-File -Path .\setup.ps1
# Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
# o usar para ejecutar sin cambiar la politica
# powershell -ExecutionPolicy Bypass -File .\setup.ps1

# Function to check if script is running as administrator
function Test-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check for elevated permissions
if (-not (Test-Admin)) {
    Write-Host "This script requires elevated privileges (Administrator). Please run as Administrator." -ForegroundColor Red
    exit
}

# Winget has never worked properly, especially on clean installations, even though it comes pre-installed. The installation is often broken, preventing it from running or updating. The best solution is to install it directly.

# 1. Obtener información de la última versión
$repo = "microsoft/winget-cli"
$urlApi = "https://api.github.com/repos/$repo/releases/latest"

try {
    Write-Host "Consultando última versión..." -ForegroundColor Cyan
    $latestRelease = Invoke-RestMethod -Uri $urlApi
    $latestVersionTag = $latestRelease.tag_name.Replace('v', '').Trim()
    $requiredVersion = [version]$latestVersionTag
    $downloadUrl = ($latestRelease.assets | Where-Object { $_.name -like "*.msixbundle" }).browser_download_url | Select-Object -First 1

    # 2. Comprobar versión actual
    $currentVersion = [version]"0.0.0.0"
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        $currentVersion = [version](winget -v).Replace('v', '').Trim()
    }

    if ($currentVersion -ge $requiredVersion) {
        Write-Host "✅ Winget ya está actualizado ($currentVersion)." -ForegroundColor Green
    } else {
        Write-Host "🚀 Actualizando de $currentVersion a $requiredVersion..." -ForegroundColor Yellow
        
        $destination = "$env:USERPROFILE\Downloads\Winget_Update.msixbundle"
        Invoke-WebRequest -Uri $downloadUrl -OutFile $destination

        # --- AQUÍ ESTÁ LA SOLUCIÓN AL ERROR 0x80073D02 ---
        Write-Host "Cerrando procesos bloqueantes..." -ForegroundColor Gray
        # Cerramos cualquier instancia de Winget o del instalador
        Get-Process -Name "WinGet", "AppInstaller" -ErrorAction SilentlyContinue | Stop-Process -Force
        Start-Sleep -Seconds 2 # Damos un respiro al sistema

        Write-Host "Instalando paquete (forzando cierre de aplicaciones)..."
        # Usamos -ForceApplicationShutdown para que Windows mismo intente cerrar lo que estorbe
        Add-AppxPackage -Path $destination -ForceApplicationShutdown -ErrorAction Stop
        
        Write-Host "✅ ¡Listo! Winget actualizado a la versión $requiredVersion." -ForegroundColor Green
        Remove-Item $destination -ErrorAction SilentlyContinue
    }
} catch {
    Write-Host "❌ Error: $_" -ForegroundColor Red
    Write-Host "Nota: Asegúrate de ejecutar PowerShell como ADMINISTRADOR." -ForegroundColor Yellow
}

# Function to check if PowerShell 7+ is running
function Is-PowerShell7 {
    return $PSVersionTable.PSVersion.Major -ge 7
}

# Ensure we're running PowerShell 7, if not, install it and exit the script
if (-not (Is-PowerShell7)) {
    Write-Host "PowerShell 7 or higher is required. Installing PowerShell 7..."
    try {
        winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent
        Write-Host "PowerShell 7 installed successfully."
        Write-Host "Continue in PowerShell 7."
        Start-Sleep -Seconds 2
        # Switch to powershell 7
        $desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "setup.ps1")
        Start-Process "pwsh" -ArgumentList "-NoProfile -NoExit -File `"$desktopPath`""

        exit
    } catch {
        Write-Host "PowerShell 7 installation failed. Exiting script."
        exit
    }
} else {
    Write-Host "PowerShell 7 is already running."
}

# --- Función de detección mejorada ---
function Is-FontInstalled {
    param (
        [string]$FontName
    )
    # Rutas del registro donde Windows guarda las fuentes instaladas
    $regPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts",
        "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
    )

    foreach ($path in $regPaths) {
        if (Test-Path $path) {
            # Buscamos si alguna propiedad del registro contiene el nombre de la fuente
            $fonts = Get-ItemProperty -Path $path
            if ($fonts.PSObject.Properties.Name -like "*$FontName*") {
                return $true
            }
        }
    }
    return $false
}

# --- 1. Instalar Oh My Posh ---
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    try {
        Write-Host "Instalando Oh My Posh..." -ForegroundColor Cyan
        winget install JanDeDobbeleer.OhMyPosh --source winget --accept-package-agreements --accept-source-agreements --silent
        Write-Host "Instalado. Reiniciando script para cargar variables..." -ForegroundColor Green
        
        $desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, "Desktop", "setup.ps1")
        Start-Process "pwsh" -ArgumentList "-NoProfile -File `"$desktopPath`""
        exit # Cerramos la sesión actual para evitar duplicidad
    } catch {
        Write-Host "Error instalando Oh My Posh." -ForegroundColor Red
    }
}

# --- 2. Instalar Fuentes (si OMP existe) ---
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    $fuentes = @("Meslo", "Hack")

    foreach ($f in $fuentes) {
        if (-not (Is-FontInstalled -FontName "$f*Nerd Font")) {
            Write-Host "Instalando fuente $f..." -ForegroundColor Yellow
            try {
                # Usamos el nombre que oh-my-posh reconoce internamente
                $nombreFuente = $f.ToLower()
                oh-my-posh font install $nombreFuente
                Write-Host "✅ $f instalada correctamente." -ForegroundColor Green
            } catch {
                Write-Host "❌ Error al instalar la fuente $f." -ForegroundColor Red
            }
        } else {
            Write-Host "✅ La fuente $f ya está instalada. Saltando..." -ForegroundColor Gray
        }
    }
}

# Get the path of settings.json from Windows Terminal
$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Ensure that settings.json exists before attempting to modify it
if (-not (Test-Path $terminalSettingsPath)) {
    Write-Host "Settings.json not found. Please ensure Windows Terminal is installed and run at least once." -ForegroundColor Red
    exit
}

# Read the settings.json file
$settingsJson = Get-Content -Path $terminalSettingsPath -Raw | ConvertFrom-Json

# Create the 'defaults' section if it doesn't exist.
if (-not $settingsJson.profiles.defaults) {
    $settingsJson.profiles.defaults = @{}
}

# Create the 'font' section if it doesn't exist.
if (-not $settingsJson.profiles.defaults.font) {
    $settingsJson.profiles.defaults | Add-Member -MemberType NoteProperty -Name "font" -Value @{}
}

$settingsJson.profiles.defaults.font.face = "Hack Nerd Font"

# Save changes to settings.json
$settingsJson | ConvertTo-Json -Depth 100 | Set-Content -Path $terminalSettingsPath -Force

Write-Host "Settings.json updated with Hack Nerd Font and profiles." -ForegroundColor Green

# 1. Obtener la ruta del perfil de forma automática
$profilePath = $PROFILE

# 2. Crear el archivo si no existe
if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -Type File -Force
    Write-Host "Archivo de perfil creado." -ForegroundColor Cyan
}

# 3. Función de ayuda corregida
function Add-IfNotExists {
    param (
        [string]$path,
        [string]$line
    )
    # Leemos el archivo línea por línea (sin -Raw) para que sea un array
    $currentContent = Get-Content -Path $path
    
    # Comprobamos si la línea ya existe en el array
    if ($currentContent -notcontains $line) {
        Add-Content -Path $path -Value $line
        Write-Host "Añadido: $line" -ForegroundColor Gray
    }
}

# 4. Bloque de edición
try {
    Add-IfNotExists $profilePath 'oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/pentescatination.omp.json | Invoke-Expression'
    Add-IfNotExists $profilePath 'Import-Module -Name Terminal-Icons'
    Add-IfNotExists $profilePath 'Import-Module CompletionPredictor'
    Add-IfNotExists $profilePath '$env:POSH_GIT_ENABLED = $true'
    Add-IfNotExists $profilePath 'Set-PSReadLineOption -PredictionViewStyle ListView'
    Add-IfNotExists $profilePath 'Write-Host "                  Rebel Alliance " -ForegroundColor red'
    Add-IfNotExists $profilePath 'Write-Host "                  󱋌  " -NoNewline'
    Add-IfNotExists $profilePath 'Write-Host  (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() 󱋌'

    Write-Host "✅ Perfil de PowerShell actualizado correctamente." -ForegroundColor Green
} catch {
    Write-Host "❌ Falló la actualización del perfil: $_" -ForegroundColor Red
}

# Set execution policy to Unrestricted for current user
try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    Write-Host "Execution policy set to Unrestricted."
} catch {
    Write-Host "Failed to set execution policy. Continuing..."
}

# Descargar tema personalizado si Oh My Posh está instalado
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        $themeDir = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes"
        $themePath = Join-Path $themeDir "pentescatination.omp.json"

        # --- SOLUCIÓN: Crear la carpeta si no existe ---
        if (-not (Test-Path $themeDir)) {
            New-Item -Path $themeDir -ItemType Directory -Force | Out-Null
            Write-Host "Carpeta de temas creada." -ForegroundColor Gray
        }

        Write-Host "Descargando tema personalizado..." -ForegroundColor Cyan
        $url = "https://raw.githubusercontent.com/surgatengit/Procrastinateshell/main/pentescatination.omp.json"
        
        # Descarga el archivo
        Invoke-WebRequest -Uri $url -OutFile $themePath -ErrorAction Stop
        
        Write-Host "✅ Tema descargado con éxito en: $themePath" -ForegroundColor Green
    } catch {
        Write-Host "❌ Error al descargar el tema: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Oh My Posh no encontrado, saltando descarga de tema." -ForegroundColor Yellow
}

# Install Terminal Icons
try {
    Install-Module -Name Terminal-Icons -Force
    Write-Host "Terminal Icons module installed successfully."
} catch {
    Write-Host "Failed to install Terminal Icons. Continuing..."
}

# Install CompletionPredictor
try {
    Install-Module -Name CompletionPredictor -Force
    Write-Host "CompletionPredictor module installed successfully."
} catch {
    Write-Host "Failed to install CompletionPredictor. Continuing..."
}

# Install Git (required for posh-git)
try {
    winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent
    Write-Host "Git installed successfully."
} catch {
    Write-Host "Git installation failed. Continuing..."
}

# Install posh-git (if Git is installed)
if (Get-Command git -ErrorAction SilentlyContinue) {
    try {
        Install-Module posh-git -Scope CurrentUser -Force
        Write-Host "posh-git installed successfully."
    } catch {
        Write-Host "posh-git installation failed. Continuing..."
    }
} else {
    Write-Host "Git not found, skipping posh-git installation."
}

function Install-App {
    param (
        [string]$AppId,
        [string]$AppName
    )
    try {
        winget install -e --id $AppId --accept-package-agreements --accept-source-agreements --silent --source winget
        Write-Host "$AppName installed successfully."
    } catch {
        Write-Host "$AppName installation failed. Continuing..."
    }
}

# Lista de aplicaciones a instalar
$apps = @(
    @{ id = "Mozilla.Firefox.es-ES"; name = "Firefox" },
    @{ id = "Mobatek.MobaXterm"; name = "MobaXterm" },
    @{ id = "Microsoft.PowerToys"; name = "PowerToys" },
    @{ id = "Microsoft.VisualStudioCode"; name = "Visual Studio Code" },
    @{ id = "OpenVPNTechnologies.OpenVPNConnect"; name = "Visual Studio Code" },
    @{ id = "7zip.7zip"; name = "7zip" },
    @{ id = "dnSpyEx.dnSpy"; name = "dnSpyEX" },
    @{ id = "Obsidian.Obsidian"; name = "Obsidian" }
)

# Instalar todas las aplicaciones
foreach ($app in $apps) {
    Install-App -AppId $app.id -AppName $app.name
}

# Update PowerShell Help
if (-not (Get-Help -ErrorAction SilentlyContinue)) {
    try {
        Update-Help
        Write-Host "PowerShell Help updated successfully."
    } catch {
        Write-Host "Failed to update PowerShell Help. Continuing..."
    }
} else {
    Write-Host "PowerShell Help is already updated."
}

Write-Host "Script execution completed!" -ForegroundColor Green
Write-Host "Please reload powershell terminal!" -ForegroundColor Green
