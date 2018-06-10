#Requires -RunAsAdministrator
Get-Service | where {$_.Name -eq "sshd"}  | Start-Service
Get-Service | where {$_.Name -eq "sshd"}  | Format-List

