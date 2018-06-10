#Requires -RunAsAdministrator

function my_deactive_service($name, [ref]$result) {
  $filter_block=[ScriptBlock]::Create("`$_.Name -eq `"$name`"")
  $result.Value=Get-Service | where $filter_block
  if (!$result.Value) { throw "unable to find $name" }
  Stop-Service $result.Value
}

