# Guia do Usuário - DataLake FB v2

Bem-vindo ao Guia do Usuário do DataLake FB v2. Este documento serve como ponto central para entendimentos, operações e manutenção da plataforma de dados.

## Índice

### [Capítulo 1: Introdução e Arquitetura](./01_introducao_arquitetura.md)
Conceitos fundamentais, visão geral da arquitetura, fluxo de dados e tecnologias utilizadas.
- O que é o DataLake FB v2?
- Componentes Principais (Iceberg, Spark, MinIO, Trino, Superset)
- Fluxo de Dados (End-to-End)

### [Capítulo 2: Instalação e Configuração](./02_instalacao_configuracao.md)
Guia passo-a-passo para colocar o ambiente em funcionamento a partir do zero.
- Pré-requisitos
- Configuração do Ambiente (.env)
- Inicialização dos Serviços (Docker Compose)
- Validação da Instalação

### [Capítulo 3: Ingestão e Gerenciamento de Dados](./03_gestao_dados.md)
Como carregar, transformar e gerenciar dados dentro do DataLake.
- Scripts de Ingestão
- Gerenciamento de Tabelas Iceberg
- Particionamento e Evolução de Schema

### [Capítulo 4: Análise e Visualização](./04_analise_visualizacao.md)
Consumindo os dados para gerar valor e insights.
- Consultas SQL com Trino
- Criação de Dashboards no Apache Superset
- Conectando Ferramentas Externas

### [Capítulo 5: Operações e Manutenção](./05_operacoes.md)
Rotinas para manter a saúde, segurança e integridade do DataLake.
- Backup e Restauração
- Recuperação de Desastres (Drills)
- Monitoramento de Serviços
- Segurança e Controle de Acesso

### [Capítulo 6: Desenvolvimento e Testes](./06_desenvolvimento.md)
Guia para desenvolvedores contribuírem e estenderem a plataforma.
- Estrutura do Código Fonte
- Executando a Suíte de Testes
- Adicionando Novas Dependências
