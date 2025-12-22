# Instruções Personalizadas do Copilot para este Repositório

Estas instruções definem como o GitHub Copilot deve gerar código, sugestões e explicações dentro deste projeto. Elas têm prioridade sobre comportamentos padrão.

---

## 1. Idioma e Estilo

- Sempre responder em **português do Brasil**.
- Produzir código limpo, legível e sustentável.
- Usar nomes descritivos.
- Evitar explicações desnecessárias.

---

## 2. Arquivos de Contexto Obrigatórios

O Copilot deve SEMPRE considerar e respeitar estes arquivos (paths atuais):

### `docs/00-overview/CONTEXT.md` (fonte da verdade)

Regras:
1. Ao iniciar **qualquer tarefa**, consultar este arquivo.
2. Ao sugerir soluções, alinhar com padrões e arquiteturas já definidas.
3. Se uma solução introduzir novo padrão ou decisão técnica, sugerir atualizar o `docs/00-overview/CONTEXT.md`.

### `docs/40-troubleshooting/PROBLEMAS_ESOLUCOES.md`
- Registro oficial de erros e correções.
- Antes de sugerir soluções, verificar se o problema já está documentado.
- Evitar repetir erros conhecidos.

---

## 3. Boas Práticas Gerais

- Funções pequenas e bem definidas.
- Aplicar DRY (não duplicar código).
- Sugerir soluções simples e claras.
- Evitar credenciais ou segredos no código.
- Apontar riscos quando forem identificados.

---

## 4. Convenções por Linguagem

### Python
- Seguir PEP8.
- Ser idiomático.
- Modularizar.
- Comentar apenas o necessário.

### JavaScript/TypeScript
- Nunca usar `var`.
- Usar `const` e `let`.
- Usar padrões modernos.
- Evitar dependências desnecessárias.

---

## 5. APIs e Backend

- Estruturar REST com handlers → serviços → repositórios.
- Validar entradas.
- Tratar erros corretamente.
- Nunca expor detalhes sensíveis.

---

## 6. Docker e Infraestrutura

- Preferir imagens leves.
- Usar multi-stage builds.
- Manter configs sensíveis como variáveis de ambiente.
- Para arquivos de config remotos, seguir o workflow da seção **11**.

---

## 6.1 Vault (easy.gti.local) e Segredos

- Nunca hardcodear `VAULT_ADDR` ou `VAULT_TOKEN`; sempre usar variáveis de ambiente.
- Para comandos, gerar scripts/requests (PowerShell/curl/Python) assumindo `VAULT_ADDR` e `VAULT_TOKEN` já exportados.
- Referência rápida de caminhos: segredos em `kv` via `/v1/kv/data/<path>`; headers com `X-Vault-Token`.
- Tratativas: se retorno `sealed: true`, orientar unseal via API; se `permission denied`, sugerir inspecionar policies do token.
- Seguir o "Manual de Operações: Copilot & Vault" descrito pelo usuário; o Copilot atua apenas como gerador de comandos, execução é feita no terminal pelo usuário.

---

## 7. Banco de Dados

- Preferir SQL simples e eficiente.
- Priorizar prepared statements.
- Comentar queries complexas de forma breve.

---

## 8. Múltiplas soluções possíveis

Escolher a solução:
- mais simples  
- mais clara  
- mais sustentável  
- alinhada com `docs/CONTEXT.md`

---

## 9. Comportamento no VS Code

- Considerar automaticamente:
  - `docs/CONTEXT.md`
  - `docs/PROBLEMAS_ESOLUCOES.md`
  - estrutura do workspace
- Nunca contradizer padrões já definidos nos arquivos acima.

---

## 10. Registro de Problemas

Ao detectar:
- erros recorrentes,
- más práticas,
- falhas arquiteturais,
- soluções relevantes…

Sugerir registrar no `docs/PROBLEMAS_ESOLUCOES.md`.

---

## 11. Workflow de Edição Remota/Containers

Para qualquer arquivo remoto ou dentro de container:

1. **Proibido editar direto via nano/vim** no servidor ou container.
2. Se o conteúdo do arquivo for desconhecido, solicitar leitura (`cat`).
3. Tentar copiar/ler como usuário normal primeiro.
4. Se houver “Permission Denied”, sugerir repetir com `sudo` ou root.
5. Copiar o arquivo remoto para a **estrutura local espelhada** no projeto.
6. Editar localmente.
7. Enviar de volta usando `scp`, `rsync` ou `docker cp`.
8. Autenticação sempre com **chave SSH**.
9. Usar `/keys` como diretório padrão de chaves.

---

## 12. Objetivo Final

Toda sugestão deve:
- respeitar a arquitetura definida em `docs/CONTEXT.md`;
- seguir boas práticas modernas;
- não inventar conteúdo de arquivos remotos;
- manter a documentação sempre atualizada;
- preservar segurança e integridade do projeto.
