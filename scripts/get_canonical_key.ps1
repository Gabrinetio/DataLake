function Get-CanonicalSshKeyPath {
    param(
        [string]$OverrideEnvVarName = 'SSH_KEY_PATH'
    )

    # 1. Se setada por env var, use ela
    $envPath = [System.Environment]::GetEnvironmentVariable($OverrideEnvVarName)
    if ($envPath -and (Test-Path $envPath)) { return $envPath }

    # 2. Caminho canônico no repositório relativo ao script
    $candidate = Join-Path $PSScriptRoot 'key\ct_datalake_id_ed25519'
    if (Test-Path $candidate) { return $candidate }

    # 3. Fallback para chave pessoal do usuário (compatibilidade)
    $userFallback = Join-Path $env:USERPROFILE '.ssh\id_ed25519'
    return $userFallback
}

Export-ModuleMember -Function Get-CanonicalSshKeyPath
