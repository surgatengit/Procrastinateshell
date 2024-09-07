# automated script
# Ensure Winget is installed and registered
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "Winget not found, attempting to install..."
    Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
    Start-Sleep -Seconds 10
}

# Install PowerShell using Winget
winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent

# Install Windows Terminal
winget install --id Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent

# Install Oh My Posh
winget install JanDeDobbeleer.OhMyPosh -s winget

# Install Meslo Nerd Font via Oh My Posh
oh-my-posh font install meslo

# Install Hack Nerd Font manually (alternative to Meslo if needed)
Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip -OutFile Fonts.zip
Expand-Archive .\Fonts.zip -DestinationPath "$env:USERPROFILE\Fonts"
Start-Sleep -Seconds 5
Get-ChildItem -Path "$env:USERPROFILE\Fonts" -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach-Object {
    (New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($_.FullName, 0x10)
}

# Create and edit PowerShell profile
$profilePath = "$PROFILE"
if (-not (Test-Path $profilePath)) {
    New-Item -Path $profilePath -Type File -Force
}
Add-Content -Path $profilePath -Value 'oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/procrastinationcandidate.omp.json | Invoke-Expression'
Add-Content -Path $profilePath -Value 'Import-Module -Name Terminal-Icons'
Add-Content -Path $profilePath -Value '$env:POSH_GIT_ENABLED = $true'
Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -PredictionSource HistoryAndPlugin'
Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -PredictionViewStyle ListView'
Add-Content -Path $profilePath -Value 'Set-PSReadLineOption -EditMode Windows'
Add-Content -Path $profilePath -Value 'Write-Host "                  Rebel Alliance " -ForegroundColor red'
Add-Content -Path $profilePath -Value 'Write-Host "                  󱋌  " -NoNewline'
Add-Content -Path $profilePath -Value 'Write-Host  (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() 󱋌'

# Set execution policy to Unrestricted for current user
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force

# Download custom Oh My Posh theme
$themePath = "$env:LOCALAPPDATA\Programs\oh-my-posh\themes\procrastinationcandidate.omp.json"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/surgatengit/Procrastinateshell/main/procrastinationcandidate.omp.json" -OutFile $themePath

# Install Terminal Icons
Install-Module -Name Terminal-Icons -Force

# Install Git (required for posh-git)
winget install -e --id Git.Git

# Install posh-git
Install-Module posh-git -Scope CurrentUser -Force

# Update PowerShell Help
Update-Help

Write-Host "Installation and configuration completed!" -ForegroundColor Green
