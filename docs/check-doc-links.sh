#!/bin/bash
# check-doc-links.sh - Validador de links internos em documentação
# Verifica se todos os links internos em arquivos Markdown apontam para arquivos/diretórios existentes

set -e

ERRORS=0
WARNINGS=0
TOTAL_LINKS=0
CHECKED_FILES=0

# Cores
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS_DIR="${1:-$PROJECT_ROOT/docs}"
IGNORE_PATTERN="(http|https|mailto|javascript|#)"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Validador de Links de Documentação${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Diretório do projeto: $PROJECT_ROOT"
echo "Diretório a validar: $DOCS_DIR"
echo ""

# Encontrar todos os arquivos Markdown
while IFS= read -r file; do
    if [ -f "$file" ]; then
        CHECKED_FILES=$((CHECKED_FILES + 1))
        
        # Extrair todos os links do arquivo
        while IFS= read -r line; do
            if [[ -n "$line" ]]; then
                # Padrão: [texto](caminho)
                if [[ $line =~ \[.*\]\(([^\)]+)\) ]]; then
                    link="${BASH_REMATCH[1]}"
                    TOTAL_LINKS=$((TOTAL_LINKS + 1))
                    
                    # Ignorar links externos
                    if [[ $link =~ $IGNORE_PATTERN ]]; then
                        continue
                    fi
                    
                    # Extrair caminho (sem âncora)
                    path=$(echo "$link" | sed 's/#.*//')
                    
                    # Resolver caminho relativo do arquivo
                    file_dir=$(dirname "$file")
                    
                    # Se o caminho é relativo ao projeto, resolver a partir da raiz
                    if [[ "$path" == docs/* ]] || [[ "$path" == .github/* ]] || [[ "$path" == infra/* ]]; then
                        full_path="$PROJECT_ROOT/$path"
                    else
                        # Caminho relativo ao arquivo
                        full_path="$file_dir/$path"
                    fi
                    
                    # Normalizar caminho
                    full_path=$(cd "$(dirname "$full_path")" 2>/dev/null && pwd || echo "NOT_FOUND")/"$(basename "$path")" 2>/dev/null || echo "NOT_FOUND"
                    full_path=$(echo "$full_path" | sed 's|/\./|/|g' | sed 's|//|/|g')
                    
                    if [[ ! -e "${full_path%/*}/$( basename "$full_path")" ]]; then
                        ERRORS=$((ERRORS + 1))
                        echo -e "${RED}✗ ERRO${NC} em $file"
                        echo -e "  Link: ${RED}$link${NC}"
                        echo ""
                    fi
                fi
            fi
        done < <(grep -o '\[.*\]([^)]*)' "$file" || true)
    fi
done < <(find "$DOCS_DIR" -name "*.md" -type f)

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Relatório de Validação${NC}"
echo -e "${BLUE}========================================${NC}"
echo "Arquivos Markdown verificados: $CHECKED_FILES"
echo "Total de links encontrados: $TOTAL_LINKS"
echo -e "Erros (links quebrados): ${RED}$ERRORS${NC}"
echo -e "Avisos: ${YELLOW}$WARNINGS${NC}"
echo ""

if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ Todos os links estão válidos!${NC}"
    exit 0
else
    echo -e "${RED}✗ Encontrados $ERRORS link(s) quebrado(s)${NC}"
    exit 1
fi
