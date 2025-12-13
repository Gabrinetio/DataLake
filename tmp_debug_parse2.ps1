param([string]$path)
$errors = $null
$tokens = $null
[System.Management.Automation.Language.Parser]::ParseFile($path,[ref]$tokens,[ref]$errors) | Out-Null
if ($errors) { foreach ($e in $errors) { Write-Host '----'; Write-Host 'Message:'; Write-Host $e.Message; Write-Host 'StartLine:' $e.Extent.StartLine; Write-Host 'EndLine:' $e.Extent.EndLine; Write-Host 'Text:'; Write-Host $e.Extent.Text }} else { Write-Host 'No parse errors' }