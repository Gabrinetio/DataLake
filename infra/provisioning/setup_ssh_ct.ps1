# Script padrão para configurar acesso SSH por chave a um CT Proxmox
# Se falhar, use método manual: gere chave local, SSH root@CT, adicione pub key a authorized_keys do user.
# Uso: .\setup_ssh_ct.ps1 -CtId 109 -CtIp "192.168.4.32" -User "datalake" -RootPassword "SENHA_ROOT"

param(
    [Parameter(Mandatory=$true)]
    [string]$CtId,

    [Parameter(Mandatory=$true)]
    [string]$CtIp,

    [Parameter(Mandatory=$true)]
    [string]$User,

    [Parameter(Mandatory=$true)]
    [string]$RootPassword
)

# Gerar chave SSH se não existir
$keyPath = "$env:USERPROFILE\.ssh\id_ed25519"
if (!(Test-Path $keyPath)) {
    ssh-keygen -t ed25519 -f $keyPath -N '' -C "$User@local"
}

# Obter chave pública
$pubKey = Get-Content "$keyPath.pub"

# Conectar ao CT e configurar (assumindo acesso root)
# Nota: Execute manualmente os comandos abaixo no CT após conectar
Write-Host "Execute estes comandos no CT $CtIp como root:"
Write-Host "mkdir -p /home/$User/.ssh"
Write-Host "echo '$pubKey' >> /home/$User/.ssh/authorized_keys"
Write-Host "chmod 600 /home/$User/.ssh/authorized_keys"
Write-Host "chown -R $User`:$User /home/$User/.ssh"

# Testar
Write-Host "Teste com: ssh $User@$CtIp"


