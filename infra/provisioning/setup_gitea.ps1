# Script para configurar e iniciar o Gitea localmente
# Certifique-se de que o Docker Desktop esteja rodando

Write-Host "Configurando Gitea localmente..." -ForegroundColor Green

# Verificar se docker-compose está disponível
if (!(Get-Command docker-compose -ErrorAction SilentlyContinue)) {
    Write-Host "docker-compose não encontrado. Instalando..." -ForegroundColor Yellow
    # Assumindo Docker Desktop instalado
    Write-Host "Certifique-se de que o Docker Desktop esteja instalado e rodando." -ForegroundColor Red
    exit 1
}

# Verificar se .env existe
if (!(Test-Path .env)) {
    Write-Host "Arquivo .env não encontrado. Copiando de .env.example..." -ForegroundColor Yellow
    Copy-Item .env.example .env
    Write-Host "Edite o arquivo .env com as credenciais do Gitea antes de continuar." -ForegroundColor Red
    Write-Host "Variáveis necessárias: GITEA_DB_PASSWORD, GITEA_SECRET_KEY" -ForegroundColor Yellow
    exit 1
}

# Carregar variáveis do .env
Get-Content .env | ForEach-Object {
    if ($_ -match '^([^=]+)=(.*)$') {
        $key = $matches[1]
        $value = $matches[2]
        Set-Variable -Name $key -Value $value -Scope Script
    }
}

# Verificar se as variáveis estão definidas
if (!$GITEA_DB_PASSWORD -or !$GITEA_SECRET_KEY) {
    Write-Host "Variáveis GITEA_DB_PASSWORD e GITEA_SECRET_KEY devem estar definidas no .env" -ForegroundColor Red
    exit 1
}

Write-Host "Iniciando Gitea..." -ForegroundColor Green
docker-compose -f docker-compose.gitea.yml up -d

Write-Host "Aguardando inicialização..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host "Gitea configurado com sucesso!" -ForegroundColor Green
Write-Host "Acesse: http://localhost:3000" -ForegroundColor Cyan
Write-Host "Usuário admin: admin" -ForegroundColor Cyan
Write-Host "Senha: a definida na primeira configuração web" -ForegroundColor Cyan