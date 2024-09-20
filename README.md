# Windows Powershell Terminal Configuration

Update, automatic setup.ps1 for fresh windows installation.

![pentestcatinationShell](https://github.com/user-attachments/assets/73f8e32d-9d5e-4285-920f-af83527dc2fe)

# Install script (Recommended)
Download setup.ps1 and run from elevated powershell 


# Manual installation
## Winget
<!-- 
> [!NOTE]
> Since winget is still in development, it may fail or its installation process and pre-installation on certain systems may change without prior notice. Below are several methods to install it.

If you're logging in for the first time and winget is not available, you can register it by opening PowerShell and running the following command:
```Powershell
Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe
```
-->
## Install or Update: Winget, Powershell and Windows Terminal

To install winget (tested on Windows 11 23H2), if it's not working properly, use the following link to install it from the Microsoft Store:
```
https://apps.microsoft.com/store/detail/instalador-de-aplicaci%C3%B3n/9NBLGGH4NNS1?hl=es-es&gl=es
```
From a elevated command prompt (cmd):
```console
winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent
```
If an error occurs, use this command:
```powershell
Add-AppxPackage -Path "https://cdn.winget.microsoft.com/cache/source.msix"
```
To install Windows Terminal
```console
winget install --id=Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent
```

## Oh My Posh

Install Oh My Posh with winget:
```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget --accept-package-agreements --accept-source-agreements --silent
```

### Install Fonts

New Metod, (directly from Oh-My-Posh):
```
oh-my-posh font install meslo
oh-my-posh font install hack
```
<!--  No es necesario desde que oh-my-posh incluye instalación directa
Manual method:
1. Download, unzip, and install Hack Nerd Font from `https://www.nerdfonts.com`
2. In the Windows Terminal settings UI, go to the "Advanced" tab of each profile and select the Meslo NF font.
3. Save the changes.

To install Hack Nerd Font via a one-line PowerShell script:
```powershell
Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip -OutFile Fonts.zip && Expand-Archive .\Fonts.zip & start-sleep -s 4 && Get-ChildItem -Path ./Fonts -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($_.FullName,0x10)}
```
-->
### Create and Edit Profile
Close powershell console 5.0 and open terminal, choose powershell 7.x and...

Create a profile:
```powershell
New-Item -Path $PROFILE -Type File -Force
```
Edit the profile:
```powershell
notepad $PROFILE
```
<!-- 
### Set Execution Policy
Review and set de execution policy:
```powershell
Get-ExecutionPolicy -list
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser
```
### Theme Path
Check the path Oh My Posh themes:
```powershell
$env:POSH_THEMES_PATH
```
-->

Add the following lines to your profile and save:
```text
oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/procrastinationcandidate.omp.json | Invoke-Expression
Import-Module -Name Terminal-Icons
$env:POSH_GIT_ENABLED = $true
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Write-Host "                  Alianza Rebelde " -ForegroundColor red
Write-Host "                  󱋌  " -NoNewline
Write-Host  (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() 󱋌
#Get-NetIPConfiguration -InterfaceAlias Ethernet
``` 
Download a custom theme to `~/AppData/Local/Programs/oh-my-posh/themes/`

![pentestcastination.omp.json](https://gist.github.com/surgatengit/f5009b5f484138cdbd895acdfa152805)


## Install Terminal Icons
In powershell 7, run the following command:
```powershell
Install-Module -Name Terminal-Icons
```
## Install posh-git
First install Git: 
```powershell
winget install -e --id Git.Git --accept-package-agreements --accept-source-agreements --silent
```
From an elevated PowerShell window:
```powershell
Install-Module posh-git -Scope CurrentUser -Force
```

## Update powershell Help
Finally, update the help files:
```powershell
Update-Help
```
