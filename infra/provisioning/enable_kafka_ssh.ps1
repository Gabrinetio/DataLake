# Script para habilitar SSH no container Kafka (VMID 104) como root com senha
# Execute este script no PowerShell local após configurar a chave SSH

param(
    [string]$HostIP = "192.168.4.37",
    [string]$User = "datalake",
    [string]$ContainerVMID = "109",
    [string]$RootPassword = "SUA_SENHA_AQUI"  # Substitua por uma senha forte
)

# Função para executar comando via SSH
function Invoke-SSHCommand {
    param([string]$Command)
    & ssh "${User}@${HostIP}" $Command
}

Write-Host "Verificando conexão SSH e status do container..."
Invoke-SSHCommand "pct list | grep $ContainerVMID"

Write-Host "Instalando OpenSSH Server no container..."
Invoke-SSHCommand "pct exec $ContainerVMID -- apt update"
Invoke-SSHCommand "pct exec $ContainerVMID -- apt install -y openssh-server"

Write-Host "Copiando sshd_config do container para host..."
Invoke-SSHCommand "pct exec $ContainerVMID -- cp /etc/ssh/sshd_config /tmp/sshd_config_container"
Invoke-SSHCommand "pct pull $ContainerVMID /tmp/sshd_config_container /tmp/sshd_config_local"

Write-Host "Baixando sshd_config para edição local..."
& scp "${User}@${HostIP}:/tmp/sshd_config_local" ".\sshd_config_backup"

# Editar o arquivo localmente (assumindo que você edita manualmente ou automatiza)
Write-Host "Edite o arquivo .\sshd_config_backup para:"
Write-Host "  - PermitRootLogin yes"
Write-Host "  - PasswordAuthentication yes"
Write-Host "Pressione Enter após editar..."
Read-Host

Write-Host "Enviando sshd_config editado de volta..."
& scp ".\sshd_config_editado" "${User}@${HostIP}:/tmp/sshd_config_editado"
Invoke-SSHCommand "pct push $ContainerVMID /tmp/sshd_config_editado /etc/ssh/sshd_config"

Write-Host "Definindo senha para root..."
Invoke-SSHCommand "pct exec $ContainerVMID -- bash -c `"echo 'root:$RootPassword' | chpasswd`""

Write-Host "Habilitando e reiniciando SSH..."
Invoke-SSHCommand "pct exec $ContainerVMID -- systemctl enable ssh"
Invoke-SSHCommand "pct exec $ContainerVMID -- systemctl start ssh"
Invoke-SSHCommand "pct exec $ContainerVMID -- systemctl restart ssh"

Write-Host "SSH habilitado. Teste com: ssh root@192.168.4.37"


