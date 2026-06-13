# Hermes Skills Ecosystem

O Hermes Agent possui **5 fontes de skills**:

## 1. Built-in (66 skills — já instaladas)
Vêm embutidas no Hermes Agent. Já estão em `~/.hermes/skills/`. Atualizadas via `hermes update`.

## 2. Skills Hub (skills.sh + browse.sh + GitHub)
Registro público pesquisável:
```bash
hermes skills search --source all "query"
hermes skills search --source official "docker"
hermes skills search --source github "rag"
hermes skills search --source skills-sh "database"
hermes skills search --source browse-sh "api"
```

**Fontes disponíveis:** `all`, `official`, `skills-sh`, `well-known`, `github`, `clawhub`, `lobehub`, `browse-sh`

**Instalação:**
```bash
hermes skills install <hub-id>
hermes skills inspect <hub-id>   # Preview sem instalar
```

## 3. Skill Taps (GitHub repos)
Adicionar um repositório inteiro como fonte:
```bash
hermes skills tap add https://github.com/usuario/skills-repo
hermes skills list               # Agora vê as skills do tap
```

## 4. Agente-Criadas (locais)
Skills criadas durante conversas via `skill_manage(action="create")`. Ficam em `~/.hermes/skills/<categoria>/<nome>/`. Gerenciáveis via:
```bash
hermes skills list                # Ver todas
hermes curator status             # Estado de manutenção
```

## 5. MCP Servers
Não são skills, mas extension via protocolo MCP (npx, uvx, HTTP). Configurados em `config.yaml` → `mcp_servers`. Oferecem ferramentas no lugar de instruções.

## Boas Práticas
- **66 built-in** cobrem 90% dos casos: sempre verificar `hermes skills list` antes de criar
- **Preferir criar skill própria** quando o built-in não cobre — reflete seu setup, ferramentas e padrões
- **Skills Hub** para skills da comunidade (válido antes de criar do zero)
- **Skill Taps** para skills internas de time/empresa
