# OpenCode CLI via npx

O OpenCode CLI pode ser executado via `npx` sem necessidade de instalação global com npm.

## Verificação

```bash
npx opencode-ai --version
# 1.17.5
```

## Uso

```bash
npx opencode-ai run 'Seu prompt aqui'
npx opencode-ai run 'Respond with exactly: SMOKE_OK'
```

## Smoke Test

```bash
npx opencode-ai run 'Respond with exactly: OPENCODE_SMOKE_OK'
# Saída esperada: OPENCODE_SMOKE_OK
```

## Motivação

O pacote Debian `opencode` (`apt install opencode`) instala o **OpenCode Desktop** (app Electron/GUI em `/opt/OpenCode/`), não o CLI. O CLI oficial requer npm, mas o `npx` resolve automaticamente sem instalação global.

## Provider

O OpenCode usa OpenRouter como provider padrão. A chave `OPENROUTER_API_KEY` no `.env` do Hermes é herdada automaticamente.

## Ver também

- `opencode` (skill built-in do Hermes)
- `professional-multi-agent` (delegação para coding agents)
