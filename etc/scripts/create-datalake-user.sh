#!/bin/bash

# Script para criar usuario 'datalake' com permissoes sudo no Debian Linux 12
# Este script deve ser executado como root ou com sudo

# Verificar se o usuário já existe
if id "datalake" &>/dev/null; then
    echo "Erro: O usuario 'datalake' ja existe."
    exit 1
fi

# Criar o usuário com diretório home e shell bash
sudo useradd -m -s /bin/bash datalake

# Adicionar o usuário ao grupo sudo
sudo usermod -aG sudo datalake

# Definir senha para o usuário
echo "Digite a senha para o usuario 'datalake':"
sudo passwd datalake

echo "Usuario 'datalake' criado com sucesso e adicionado ao grupo sudo."
echo "Para usar sudo, o usuario precisara da senha definida."