# Autounattend, installation script and ProcrastinateShell

## Autounattend.xml File
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
## You can also use the Automatic Install Script
The script ensures that the latest versions of winget, PowerShell, and Windows Terminal are functioning correctly on the system. It also customizes PowerShell 7 and installs or updates to the latest version the previously mentioned programs, in case they were not already installed or up to date.
This automated process streamlines the setup and maintenance of essential tools, ensuring that the user always has access to the most recent features and security updates.
> Download setup.ps1 and run from elevated powershell.
# Programs and :star2: ProcrastinateShell :star2: will be installed, in any modern Windows, server flavour too.
# Marvelous! :point_left:

# The procrastinateShell:
This is a customization for any shell, although it's primarily designed for PowerShell. Its main purpose is to provide contextual information and enhance screenshots taken during various penetration testing scenarios. However, it also includes additional features simply because they can be implemented and might prove useful.

The customization aims to streamline the pentesting process by offering relevant data at a glance, making it easier to document findings and maintain situational awareness. While its core functionality focuses on penetration testing, the versatility of this customization allows it to be adapted for other command-line work as well.

![pentestcatinationShell](https://github.com/user-attachments/assets/73f8e32d-9d5e-4285-920f-af83527dc2fe)

## Thanks to:
@cschneegans for [unattend generator](https://github.com/cschneegans/unattend-generator/)

@JanDeDobbeleer for [oh-my-posh](https://github.com/JanDeDobbeleer/oh-my-posh)
