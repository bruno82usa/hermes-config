# Profile Bruno — Primeira Configuração

Sessão: sábado, 13 de junho de 2026
Perfil: bruno
Provider: DeepSeek (deepseek-v4-flash)
Ambiente: Hermes Desktop GUI (Linux)

## Estado Inicial

O perfil **bruno** já existia com config completa, mas o SOUL.md estava vazio
(template padrão). Principais características:

- **Modelo**: deepseek-v4-flash via api.deepseek.com
- **Terminal**: backend local, shell persistente
- **Toolsets**: 20+ habilitados (browser, code_execution, delegation, web, etc.)
- **Memória**: ativada (memory + user profile)
- **Segurança**: redação de segredos + TIRITH ativos
- **Firecrawl**: conectado via assinatura Nous
- **Fallback**: nenhum configurado
- **Gateway**: nenhuma plataforma configurada

## Descoberta: $HOME Sobrescrito

O Hermes Desktop GUI redefine `$HOME` para:

```
~/.hermes/profiles/bruno/home/
```

Isso significa que:
- `~` expande para `/home/bruno/.hermes/profiles/bruno/home/`
- `hermes` comando não está no PATH do terminal
- `ls ~/.hermes/` falha — não encontra o diretório real

### Solução encontrada

Usar o caminho completo do binário:

```bash
HOME=/home/bruno /home/bruno/.local/bin/hermes config set display.language pt-br
```

Binários hermes disponíveis no sistema:
- `/home/bruno/.local/bin/hermes` — instalação padrão
- `/home/bruno/.hermes/hermes-agent/hermes` — código fonte
- `/home/bruno/.hermes/hermes-agent/venv/bin/hermes` — virtualenv

## Ações Realizadas

### 1. Idioma alterado para pt-br

```bash
$ HOME=/home/bruno /home/bruno/.local/bin/hermes config set display.language pt-br
✓ Set display.language = pt-br in /home/bruno/.hermes/profiles/bruno/config.yaml
```

### 2. Firecrawl testado

**Primeira tentativa** — timeout 504:
```
Firecrawl search failed: Unexpected error during search: Status code 504
```

**Segunda tentativa** — sucesso:
```
Buscou "previsão do tempo Rio de Janeiro hoje"
Retornou 3 resultados: Climatempo, G1, INMET
```

Conclusão: Firecrawl está funcional, timeouts 504 são transitórios.

## Lições Aprendidas

1. **Sempre explicar comandos "assustadores"** — o usuário perguntou "porque
   vc estava alterando o source do hermes?" ao ver `find / -name "hermes"`.
   Comandos que varrem o sistema inteiro parecem suspeitos.

2. **patch/write_file bloqueiam config.yaml** — arquivos de config do Hermes
   são protegidos. Usar `hermes config set` no terminal.

3. **Tool changes precisam de /reset** — alterações de ferramentas/config só
   valem em novas sessões.

## Próximos Passos Recomendados (não executados)

- Configurar fallback provider (ex: OpenRouter)
- Preencher SOUL.md com personalidade
- Ativar gateway (Telegram, Discord, etc.)
