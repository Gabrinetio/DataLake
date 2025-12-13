param()
# Checks staged files for private key PEM headers. Returns non-zero if a match is found.
$patterns = @('-----BEGIN OPENSSH PRIVATE KEY-----','-----BEGIN RSA PRIVATE KEY-----','-----BEGIN PRIVATE KEY-----')
# Files and patterns to exclude (self and known workflow files)
$excludePaths = @('scripts/check_no_private_keys.ps1','scripts/check_no_private_keys.sh','.githooks/pre-commit','.github/workflows/scan-keys.yml')
$found = $false
try {
    # If repo index exists, use git grep --cached to search staged files
    git rev-parse --git-dir > $null 2>&1
    $isRepo = $true
} catch {
    $isRepo = $false
}

if ($isRepo) {
    foreach ($p in $patterns) {
        # Build a exclude filter for git grep
        $excludeArgs = @()
        foreach ($ex in $excludePaths) { $excludeArgs += @('--', ":(exclude)$ex") }
        $matches = git grep -n --cached -- $p -- $excludeArgs 2>$null
        if ($matches) {
            Write-Host "Found pattern '$p' in staged files:`n$matches"
            $found = $true
        }
    }
} else {
    Write-Host 'Not a git repository; scanning all files on disk for key patterns.'
    foreach ($p in $patterns) {
        $matches = Select-String -Path (Get-ChildItem -Recurse -File) -Pattern $p -SimpleMatch -ErrorAction SilentlyContinue
        if ($matches) {
            foreach ($m in $matches) { Write-Host "Found: $($m.Path):$($m.LineNumber) - $p" }
            $found = $true
        }
    }
}

if ($found) { Write-Error "Private key pattern detected"; exit 1 } else { Write-Host 'No private keys detected'; exit 0 }
