# Autounattend, installation script and ProcrastinateShell

## 1- autounattend.xml File
> Unattended installation of Windows, using the configuration listed below and the ProcrastinateShell script.

### How to use:

> On a Windows 11 ISO image downloaded from Microsoft, include this file in the root folder.

When booting the computer or virtual machine with this ISO, it will perform a fully unattended installation of Windows, 
with no user intervention, using the configuration listed below and the ProcrastinateShell script.

> [!CAUTION]
> It will erase all data on the disk without asking.

It will create the following user accounts:
```
Admin:Zaq123456 (Administrator)
User:Zaq123456 (Standard user)
```
> [!WARNING]
> These keys are in plain text. Replace them in production.

Features:

Spanish, 64-bit
Generic Pro N for Workstations license.

- [x] GPT partition layout with recovery on C:
- [x] Always show file extensions.
- [x] No news or weather widget.
- [x] Classic right-click menu.
- [x] Align the taskbar to the left.
- [x] Remove Windows default icons.
- [x] Disable Edge's initial setup.
- [x] Disable fast startup.
- [x] Enable long file paths.
- [x] Allow PowerShell scripts (RemoteSigned).
- [x] Do not update the last access timestamp (improves performance).
- [x] Remove all system sounds for all users by default.
- [x] Remove suggested apps.
- [x] Disable all telemetry.
> Programs that will be installed
- Powershell 7
- Git
- Posh-git
- Firefox
- LightShot
- MobaXterm
- Nmap
- Microsoft Powertoys
- VisualStudioCode
- 7zip
- Obsidian
> [!NOTE]
> An internet connection is required for the setup, but it won't ask you to use a Microsoft account or anything like that.
----
# 2- Automatic Install Script for any windows system.
> Download setup.ps1 and run from elevated powershell.
# Programs and :star2: ProcrastinateShell :star2: will be installed. :point_left: Marvelous!

# 3- The procrastinateShell:
![pentestcatinationShell](https://github.com/user-attachments/assets/73f8e32d-9d5e-4285-920f-af83527dc2fe)

## Thanks to:
@cschneegans for [unattend generator](https://github.com/cschneegans/unattend-generator/)

@JanDeDobbeleer for [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh)
