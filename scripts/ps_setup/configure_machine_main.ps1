#Requires -RunAsAdministrator
param([string]$target_dir)

pushd "$target_dir"
Write-Host -ForegroundColor Yellow "[MAIN] Starting configuration @ $target_dir"

. .\deactivate_services.ps1
$target_svc=""
my_deactive_service "SEMgrSvc" ([ref]$target_svc)

function deactivate_realtime_antivirus() {
  $key_path="Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection\"
  $key_exist=Test-Path "$key_path"
  if(!$key_exist) { New-Item -Path "$key_path" }

  New-ItemProperty -Path "$key_path" -PropertyType DWORD -Force -Name "DisableRealtimeMonitoring" -Value 1
}

# fyou powershell otherwaide the output is not ordered
echo "" | out-host
Write-Host -ForegroundColor Yellow "[MAIN] End configuration"

