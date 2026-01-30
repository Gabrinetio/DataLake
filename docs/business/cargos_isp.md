# Cargos e Perfis de Acesso em um ISP

Este documento descreve a estrutura organizacional típica de um Provedor de Internet (ISP) e mapeia as necessidades de dados de cada função. Este mapeamento serve como base para a definição de **Controle de Acesso Baseado em Função (RBAC)** e para o desenvolvimento de dashboards no Data Lake.

## 1. Nível Estratégico (Diretoria)

Foco em visão macro, tendências de mercado e saúde financeira do negócio.

| Cargo | Responsabilidades | Necessidades de Dados (KPIs) | Role Sugerida |
| :--- | :--- | :--- | :--- |
| **CEO / Diretor Geral** | Visão global, estratégia de crescimento, investidores. | Receita Recorrente Mensal (MRR), EBITDA, Churn Rate (Cancelamento), Crescimento da Base Líquida, NPS Global. | `role_executive` |
| **CTO (Diretor Técnico)** | Estratégia tecnológica, infraestrutura, backbone. | Capacidade de Uplink (Link IP), Investimento em Rede (CAPEX), Estabilidade do Backbone, ROI de Expansão de Rede. | `role_executive` |
| **CFO (Diretor Financeiro)** | Fluxo de caixa, rentabilidade, fiscal. | Fluxo de Caixa, Margem de Lucro, Custo de Aquisição de Cliente (CAC), Lifetime Value (LTV), Inadimplência Global. | `role_executive` |

## 2. Engenharia e Operações (NOC & Campo)

Foco na disponibilidade (uptime), qualidade da experiência do cliente e manutenção da infraestrutura física e lógica.

| Cargo | Responsabilidades | Necessidades de Dados (KPIs) | Role Sugerida |
| :--- | :--- | :--- | :--- |
| **Gerente de Redes / NOC** | Monitoramento 24/7, gestão de incidentes, engenharia de tráfego. | Uptime de Concentradores/OLTs, Picos de Tráfego, Latência, Perda de Pacotes, Alarmes de Temperatura/Energia. | `role_noc_manager` |
| **Analista de Suporte N3** | Troubleshooting avançado, routing (BGP/OSPF), servidores. | Logs de Autenticação (Radius), Logs de DNS/CGNAT, Performance de Servidores, Detecção de Ataques DDoS. | `role_noc_admin` |
| **Coordenador de Campo** | Gestão de equipes de instalação e reparo. | Produtividade por Técnico, Reincidência de Defeitos, SLA de Instalação/Reparo, Estoque de Materiais. | `role_field_ops` |

## 3. Atendimento e Suporte (Customer Care)

Foco na resolução rápida de problemas e satisfação do cliente.

| Cargo | Responsabilidades | Necessidades de Dados (KPIs) | Role Sugerida |
| :--- | :--- | :--- | :--- |
| **Gerente de Atendimento** | Gestão do call center, treinamento, retenção. | Tempo Médio de Atendimento (TMA), Nível de Serviço (SLA), First Call Resolution (FCR), Retenção na URA. | `role_support_manager` |
| **Atendente (N1/N2)** | Primeiro contato, triagem técnica e financeira. | Status da Conexão em Tempo Real, Consumo de Banda do Cliente, Histórico de Faturas, Histórico de Chamados. | `role_support_agent` |

## 4. Comercial e Marketing

Foco na aquisição de novos clientes e upsell na base atual.

| Cargo | Responsabilidades | Necessidades de Dados (KPIs) | Role Sugerida |
| :--- | :--- | :--- | :--- |
| **Gerente Comercial** | Metas de vendas, gestão de vendedores/parceiros. | Vendas por Regional/Bairro, Taxa de Conversão do Funil, Vendas por Canal (Site, Porta-a-Porta). | `role_sales_manager` |
| **Analista de Marketing** | Campanhas, branding, análise de mercado. | Penetração de Mercado por Bairro, Perfil Demográfico da Base, ROI de Campanhas, Ticket Médio por Plano. | `role_marketing` |

## 5. Financeiro e Administrativo

Foco na eficiência operacional e controle de receitas.

| Cargo | Responsabilidades | Necessidades de Dados (KPIs) | Role Sugerida |
| :--- | :--- | :--- | :--- |
| **Analista de Cobrança** | Gestão de inadimplência, negociação, bloqueios. | Régua de Cobrança (Aging), Taxa de Recuperação de Crédito, Clientes Bloqueados/Suspensos. | `role_billing` |
| **Analista de Faturamento** | Emissão de notas fiscais (NF 21/22), conciliação bancária. | Faturamento Bruto vs Líquido, Conciliação de Boletos/Cartão, Erros de Faturamento. | `role_billing` |

## Resumo de Aplicação no Data Lake

Para o Data Lake FB v2, esta estrutura orienta:

1.  **Row Level Security (RLS):** Vendedores podem ver apenas dados de sua região.
2.  **Dashboards Específicos:**
    *   *Dashboard Executivo:* KPIs financeiros e de crescimento (agg).
    *   *Dashboard NOC:* Tráfego em tempo real, alarmes (raw/real-time).
    *   *Dashboard Comercial:* Mapas de calor de vendas e viabilidade.
3.  **Mascaramento de Dados:** Atendentes N1 não devem ver dados sensíveis (PII) desnecessários, enquanto o Financeiro precisa ver detalhes de pagamento.
