# Windows Powershell Terminal Configuration for Procrastination

## Update Powershell and install Windows Terminal

Mandatary First install winget (test in win11 23H2 the winget installed not works)
```
https://apps.microsoft.com/store/detail/instalador-de-aplicaci%C3%B3n/9NBLGGH4NNS1?hl=es-es&gl=es
```
From a elevated cmd
```console
winget install --id Microsoft.Powershell --source winget --accept-package-agreements --accept-source-agreements --silent
```
Windows Terminal
```console
winget install --id=Microsoft.WindowsTerminal -e --accept-package-agreements --accept-source-agreements --silent
```

## Oh My Posh

### Install Fonts
1. Download Unzip and install MesioLGM NF from `https://www.nerdfonts.com`
2. Open settings UI in Windows Terminal, in each profile advanced tab select font type MesioLGM NF
3. Save Changes.

One line powershell script to install Meslo Nerd Font
```powershell
Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Meslo.zip -OutFile Fonts.zip && Expand-Archive .\Fonts.zip & start-sleep -s 4 && Get-ChildItem -Path ./Fonts -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($_.FullName,0x10)}
```
### Install Oh My Posh
```powershell
winget install JanDeDobbeleer.OhMyPosh -s winget
```
Create profile 
```powershell
New-Item -Path $PROFILE -Type File -Force
```
Edit profile
```powershell
notepad $PROFILE
```
Execution policy, review and set

```powershell
Get-ExecutionPolicy -list
```

Add this lines and save.
```powershell
oh-my-posh init pwsh --config ~/AppData/Local/Programs/oh-my-posh/themes/procrastinatorcandidate.omp.json | Invoke-Expression
Import-Module -Name Terminal-Icons
$env:POSH_GIT_ENABLED = $true
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows
Write-Host "                                          Alianza Rebelde " -ForegroundColor red
Write-Host (Invoke-WebRequest -UseBasicParsing ifconfig.me/ip).Content.Trim() ﴣ
#Get-NetIPConfiguration -InterfaceAlias Ethernet
``` 

## Install Terminal Icons
In powershell 7 console 
```powershell
Install-Module -Name Terminal-Icons
```
## Install posh-git
First git must be installed 
```powershell
winget install -e --id Git.Git
```
From an elevated PowerShell
```powershell
Install-Module posh-git -Scope CurrentUser -Force
```
## PSReadline
Update version ships with powershell
```powershell
Install-Module PSReadLine -AllowPrerelease -Force
```
## Update powershell Help
```powershell
Update-Help
```
Change l to L in PSReadline Folder on C:\Program Files\WindowsPowerShell\Modules\PSReadline  <-- l to L to properly update help
## Change configuration to procrastination
Download and copy in C:~\AppData\Local\Programs\oh-my-posh\themes
 
https://github.com/surgatengit/Procrastinateshell/blob/main/procrastinationcandidate.omp.json
