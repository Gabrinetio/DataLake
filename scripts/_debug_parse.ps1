param([string]$Path)
$errors = $null
$tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($Path,[ref]$tokens,[ref]$errors) | Out-Null
if ($errors -and $errors.Count -gt 0) {
  Write-Host "Found $($errors.Count) errors for $Path"
  foreach ($e in $errors) {
    Write-Host "-----"
    Write-Host $e.ToString()
    Write-Host "Start: $($e.Extent.StartLineNumber) End: $($e.Extent.EndLineNumber)"
    Write-Host "Text:"
    Write-Host $e.Extent.Text
  }
  exit 1
} else {
  Write-Host "No parse errors for $Path"
}
