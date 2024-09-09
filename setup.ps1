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
# Function to get the version of Winget
function Get-WingetVersion {
    try {
        $wingetVersion = winget --version
        return $wingetVersion
    } catch {
        return $null
    }
}

# Ensure Winget is installed and up-to-date
$requiredWingetVersion = "v1.8.1911"
$currentWingetVersion = winget -v

if ($currentWingetVersion -and ($currentWingetVersion -ge $requiredWingetVersion)) {
    Write-Host "Winget version $currentWingetVersion is already installed and up to date."
} else {
    Write-Host "Winget is either not installed or outdated. Installing version $requiredWingetVersion..."

    # Download and install the latest version of Winget
    try {
        $wingetUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.8.1911/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
        $wingetDestination = "$env:USERPROFILE\Downloads\Microsoft.DesktopAppInstaller.msixbundle"

        # Download the msixbundle
        Write-Host "Downloading Winget from $wingetUrl..."
        Start-BitsTransfer -Source $wingetUrl -Destination $wingetDestination

        # Install Winget
        Write-Host "Installing Winget..."
        Add-AppxPackage -Path $wingetDestination

        Write-Host "Winget version $requiredWingetVersion installed successfully."
    } catch {
        Write-Host "Failed to install Winget. Exiting script." -ForegroundColor Red
        exit
    }
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

        Write-Host "Please restart this script in PowerShell 7."
        exit
    } catch {
        Write-Host "PowerShell 7 installation failed. Exiting script."
        exit
    }
} else {
    Write-Host "PowerShell 7 is already running."
}

# Check and install Windows Terminal if not installed
if (-not (Get-Command wt -ErrorAction SilentlyContinue)) {
    Write-Host "Windows Terminal not found, installing..."
    try {
        winget install --id Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent
        Write-Host "Windows Terminal installed successfully."
    } catch {
        Write-Host "Windows Terminal installation failed. Exiting script."
        exit
    }
} else {
    Write-Host "Windows Terminal is already installed."
}

# Install Oh My Posh
if (-not (Get-Command oh-my-posh -ErrorAction SilentlyContinue)) {
    try {
        winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements --silent
        Write-Host "Oh My Posh installed successfully."
    } catch {
        Write-Host "Oh My Posh installation failed. Continuing..."
    }
}

# Install Meslo Nerd Font and Hack Nerd Font via Oh My Posh if Oh My Posh is installed
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        oh-my-posh font install meslo
        oh-my-posh font install hack
        Write-Host "Meslo Nerd and Hack Nerd Font installed successfully."
    } catch {
        Write-Host "Failed to install Meslo and Hack Nerd Font using Oh My Posh. Continuing..."
    }
} else {
    Write-Host "Oh My Posh not found, skipping font installation."
}

# Obtener la ruta de settings.json de Windows Terminal
$terminalSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Asegurarse de que settings.json existe antes de intentar modificarlo
if (-not (Test-Path $terminalSettingsPath)) {
    Write-Host "Settings.json not found. Please ensure Windows Terminal is installed and run at least once." -ForegroundColor Red
    exit
}

# Leer el contenido del archivo settings.json
$settingsJson = Get-Content -Path $terminalSettingsPath -Raw | ConvertFrom-Json

# Crear la sección 'defaults' si no existe
if (-not $settingsJson.profiles.defaults) {
    $settingsJson.profiles.defaults = @{
        font = @{
            face = "Hack Nerd Font"
        }
    }
} else {
    # Modificar la fuente en la sección defaults
    $settingsJson.profiles.defaults.font = @{
        face = "Hack Nerd Font"
    }
}

# Guardar los cambios de nuevo en settings.json
$settingsJson | ConvertTo-Json -Depth 100 | Set-Content -Path $terminalSettingsPath -Force

Write-Host "Settings.json updated with Hack Nerd Font and profiles." -ForegroundColor Green

# Get the correct profile path depending on PowerShell version
$profilePath = if (Is-PowerShell7) {
    "$env:USERPROFILE\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
} else {
    "$env:USERPROFILE\Documents\WindowsPowerShell\profile.ps1"
}

# Create and edit PowerShell profile
try {
    if (-not (Test-Path $profilePath)) {
        New-Item -Path $profilePath -Type File -Force
    }
    Add-Content -Path $profilePath -Value 'oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/pentescatination.omp.json | Invoke-Expression'
    Add-Content -Path $profilePath -Value 'Import-Module -Name Terminal-Icons'
    Add-Content -Path $profilePath -Value '$env:POSH_GIT_ENABLED = $true'
    Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -PredictionSource HistoryAndPlugin'
    Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -PredictionViewStyle ListView'
    Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -EditMode Windows'
    Add-Content -Path $profilePath -Value 'Write-Host "                  Rebel Alliance " -ForegroundColor red'
    Add-Content -Path $profilePath -Value 'Write-Host "                  󱋌  " -NoNewline'
    Add-Content -Path $profilePath -Value 'Write-Host  (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() 󱋌'
    Write-Host "PowerShell profile created/updated successfully."
} catch {
    Write-Host "Failed to create or update PowerShell profile. Continuing..."
}

# Set execution policy to Unrestricted for current user
try {
    Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
    Write-Host "Execution policy set to Unrestricted."
} catch {
    Write-Host "Failed to set execution policy. Continuing..."
}

# Download custom Oh My Posh theme if Oh My Posh is installed
if (Get-Command oh-my-posh -ErrorAction SilentlyContinue) {
    try {
        $themePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\pentescatination.omp.json"
        Invoke-WebRequest -Uri "https://raw.githubusercontent.com/surgatengit/Procrastinateshell/main/pentescatination.omp.json" -OutFile $themePath
        Write-Host "Custom theme downloaded successfully."
    } catch {
        Write-Host "Failed to download custom theme. Continuing..."
    }
} else {
    Write-Host "Oh My Posh not found, skipping theme download."
}

# Install Terminal Icons
try {
    Install-Module -Name Terminal-Icons -Force
    Write-Host "Terminal Icons module installed successfully."
} catch {
    Write-Host "Failed to install Terminal Icons. Continuing..."
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
