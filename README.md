# Windows Powershell Terminal Configuration for Procrastination

## Update Powershell and install Windows Terminal

From a elevated powershell
```powershell
winget install --id Microsoft.Powershell --source winget
winget install --id=Microsoft.WindowsTerminal -e
```
## Oh My Posh

### Install Fonts
1. Download Unzip and install Caskadya Cove Nerd Font from `https://www.nerdfonts.com`
2. Open settings UI in Windows Terminal, in each profile advanced tab select font type CaskaydiaCove NF
3. Save Changes.

One liner powershell script to install Caskadya Cove Nerd Font
```powershell
Invoke-WebRequest -Uri https://github.com/ryanoasis/nerd-fonts/releases/download/v2.1.0/CascadiaCode.zip -OutFile Fonts.zip & Expand-Archive .\Fonts.zip & start-sleep -s 2 && Get-ChildItem -Path ./Fonts -Include '*.ttf','*.ttc','*.otf' -Recurse | ForEach {(New-Object -ComObject Shell.Application).Namespace(0x14).CopyHere($_.FullName,0x10)}
```
### Install Oh My Posh
```powershell
winget install oh-my-posh
```
Create profile 
```powershell
New-Item -Path $PROFILE -Type File -Force
```
Edit profile
```powershell
notepad $PROFILE
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
```powershell
Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
Install-Module -Name Terminal-Icons -Repository PSGallery
```
## Install posh-git
First git must be installed 
```powershell
winget install -e --id Git.Git
```
From an elevated PowerShell
```powershell
PowerShellGet\Install-Module posh-git -Scope CurrentUser -Force
```
## PSReadline
Update version ships with powershell
```powershell
pwsh.exe -noprofile -command "Install-Module PSReadLine -Force -SkipPublisherCheck -AllowPrerelease"
```
## Update powershell Help
```powershell
Update-Help
```
Change l to L in PSReadline Folder on C:\Program Files\WindowsPowerShell\Modules\PSReadline  <-- l to L to properly update help
## Change configuration to procrastination
Download and copy in C:~\AppData\Local\Programs\oh-my-posh\themes
 
https://github.com/surgatengit/Procrastinateshell/blob/main/procrastinationcandidate.omp.json
