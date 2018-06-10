# Setup a windows 10 machine

## Activate [SSH server][0]

Run on an **admin** powershell, make sure the version is really `0.0.1.0`

```powershell
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
mkdir ~/.ssh
pushd ~/.ssh
echo "<your key>" > authorized_keys
Get-Service | where {$_.Name -eq "sshd"}  | Start-Service
Get-Service | where {$_.Name -eq "sshd"}  | Format-List
```

## Install Chocolatey and useful tools

Dowload git client and push repo from arngrim. 
Connect via ssh and start a powershell session (check `.ssh/config` is using the right key)

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-RestMethod -Method Get -Uri "https://chocolatey.org/install.ps1" -OutFile "install_choco.ps1"
Set-ExecutionPolicy Bypass -Scope Process -Force
.\install_choco.ps1
Set-ExecutionPolicy Undefined -Scope Process -Force
choco upgrade chocolatey
choco install git
if((Test-Path "$env:ProgramFiles\Git\bin\git.exe") -eq $false) { throw "Installation of git was not successful" }
& "$env:ProgramFiles\Git\bin\git.exe" -h
```

## Push and run configuration scripts

```bash
jelanda="192.168.8.105"
scp -Cr ~/Programation/handy-scripts-for-work ${jelanda}:
ssh $jelanda powershell -command 'handy-scripts-for-work\configure_machine_main.ps1'
```

You may want to [create a shortcut][1] to some useful scripts (like `start_sshd`).

[0]: https://blogs.msdn.microsoft.com/powershell/2017/12/15/using-the-openssh-beta-in-windows-10-fall-creators-update-and-windows-server-1709/
[1]: https://www.askvg.com/windows-tip-pin-batch-bat-files-to-taskbar-and-start-menu/

