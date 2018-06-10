@echo off
set scriptpath=%~dp0

if not "%1"=="am_admin" (powershell start -verb runas "%0" "am_admin, %1" & exit /b)
shift
set scriptfile=%1

set ps_cmds={ ^
  $current_user = [Security.Principal.WindowsIdentity]::GetCurrent();^
  $current_id = New-Object Security.Principal.WindowsPrincipal($current_user);^
  $am_admin = $current_id.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator);^
  if ($am_admin) {^
    Write-Host -ForegroundColor Green "Am I admin ? $am_admin";^
  }^
  else {^
    Write-Host -ForegroundColor Yellow "Am I admin ? $am_admin";^
  }^
}
powershell -command "& %ps_cmds%"

powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force"

rem powershell -NonInteractive -File "%scriptpath%%scriptfile%"
@echo on
powershell -File "%scriptpath%%scriptfile%" %scriptpath%

@echo off
powershell -Command "Set-ExecutionPolicy -ExecutionPolicy Undefined -Scope CurrentUser -Force"
rem powershell -Command "Get-ExecutionPolicy -List"
pause

