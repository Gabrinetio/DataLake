param([string]$Path)
$errors = $null
$tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors) | Out-Null
if ($errors -and $errors.Count -gt 0) {
  Write-Output "ERRORS in $Path"
  foreach ($e in $errors) { Write-Output $e }
  exit 1
}
Write-Output "OK: $Path"
