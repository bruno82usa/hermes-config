---
name: github-cli-automation
description: "Workflows de automação GitHub via gh CLI — autenticação, PRs, issues, releases, gerenciamento de repositórios."
version: 1.0.0
author: Hermes Agent (Bruno's setup)
tags: [github, gh-cli, automation, git]
related_skills: [github-auth, github-pr-workflow, github-issues, github-repo-management]
permissions:
  - terminal:execute
  - network:connect:github.com
  - filesystem:read
platforms: [linux]
---

# GitHub CLI Automation

Skill para automação completa do GitHub usando gh CLI. Autenticado como **bruno82usa** com PAT de granularidade fina.

## Status da Autenticação

```bash
gh auth status
# ✓ Logged in to github.com account bruno82usa
```

## Comandos Essenciais

### Repositórios

```bash
# Listar repositórios
gh repo list bruno82usa --limit 20

# Clonar
gh repo clone bruno82usa/nome-do-repo

# Criar repositório
gh repo create nome-do-repo --public --description "Descrição" --clone

# Ver detalhes
gh repo view bruno82usa/nome-do-repo
```

### Pull Requests

```bash
# Listar PRs abertos
gh pr list --state open --limit 10

# Ver detalhes de um PR
gh pr view 123

# Criar PR
gh pr create --title "Título" --body "Descrição" --base main

# Fazer merge
gh pr merge 123 --squash
```

### Issues

```bash
# Listar issues
gh issue list --limit 10

# Criar issue
gh issue create --title "Título" --body "Descrição"

# Fechar issue
gh issue close 456
```

### Actions

```bash
# Listar workflows
gh workflow list

# Ver executions
gh run list --limit 10

# Ver logs de uma run
gh run view 123 --log
```

## Integração com o Hermes

O gh CLI está instalado e autenticado. Combinado com as skills built-in do Hermes:

- `github-auth` → Configuração de autenticação
- `github-pr-workflow` → Ciclo de vida de PRs
- `github-issues` → Gerenciamento de issues
- `github-repo-management` → Gerenciamento de repositórios

## Pitfalls

- **PAT expira** — se `gh auth status` falhar, reautenticar com o token salvo no .env
- **Two tokens**: `GITHUB_PAT` (token clássico) e `GITHUB_PAT_FINE` (granularidade fina) — ambos no .env
- **gh não está no PATH da GUI** — usar `HOME=/home/bruno /usr/bin/gh` quando dentro da GUI Desktop
- Limite de taxa da API do GitHub: 5000 requests/hora para PATs autenticados
