---
name: multi-provider-resilience
description: "Estratégia de resiliência multi-provider — fallback automático quando o provider principal cair, provedores alternativos configurados."
version: 1.0.0
author: Hermes Agent (Bruno's setup)
tags: [providers, fallback, resilience, deepseek, openrouter, gemini, huggingface, nvidia]
related_skills: [hermes-agent, hermes-self-configuration]
permissions:
  - terminal:execute
  - network:connect
platforms: [linux]
---

# Multi-Provider Resilience

Skill para gerenciar **múltiplos provedores de LLM** no Hermes Agent. Estratégia de fallback automático para garantir continuidade.

## Arquitetura

```
Provider Principal (DeepSeek v4-flash) ───→ Fallback (OpenRouter) ───→ Manual (Gemini/HF/NVIDIA)
```

## Provedores Configurados

| Provider | Modelo | API Key | Status |
|---|---|---|---|
| **DeepSeek** | `deepseek-v4-flash` | ✅ `DEEPSEEK_API_KEY` | 🟢 **Principal** |
| **OpenRouter** | `deepseek/deepseek-chat` (fallback) | ✅ `OPENROUTER_API_KEY` | 🟢 **Fallback automático** |
| **Google Gemini** | (via GOOGLE_API_KEY) | ✅ `GOOGLE_API_KEY` | 🔵 Manual |
| **HuggingFace** | (via HF_TOKEN) | ✅ `HF_TOKEN` | 🔵 Manual |
| **NVIDIA NIM** | (via NVIDIA_API_KEY) | ✅ `NVIDIA_API_KEY` | 🔵 Manual |
| **Ollama Cloud** | (via OLLAMA_API_KEY) | ✅ `OLLAMA_API_KEY` | 🔵 Manual |
| **Alibaba/Qwen** | (via QWEN_API_KEY) | ✅ `QWEN_API_KEY` | 🔵 Manual |

## Fallback Automático

```yaml
# config.yaml já configurado:
fallback_providers:
  - provider: openrouter
    model: deepseek/deepseek-chat
```

Quando DeepSeek falhar (timeout, 5xx, rate limit), o Hermes **automaticamente** tenta OpenRouter com o modelo equivalente.

## Troca Manual de Provider

```bash
# Mudar para Gemini
hermes config set model.provider gemini
hermes config set model.default gemini-2.0-flash

# Mudar para HuggingFace
hermes config set model.provider huggingface
hermes config set model.default meta-llama/Llama-3.2-1B-Instruct

# Voltar para DeepSeek
hermes config set model.provider deepseek
hermes config set model.default deepseek-v4-flash
```

## Verificação de Saúde

```bash
# Testar cada provider
curl -sf https://api.deepseek.com/v1/models -H "Authorization: Bearer $DEEPSEEK_API_KEY" > /dev/null && echo "DeepSeek: ✅" || echo "DeepSeek: ❌"
curl -sf https://openrouter.ai/api/v1/models -H "Authorization: Bearer $OPENROUTER_API_KEY" > /dev/null && echo "OpenRouter: ✅" || echo "OpenRouter: ❌"
```

## MLflow e Weights & Biases

Com o HF_TOKEN, é possível baixar modelos do HuggingFace Hub diretamente:

```bash
# Autenticar huggingface-cli
huggingface-cli login --token $HF_TOKEN

# Baixar modelo
huggingface-cli download meta-llama/Llama-3.2-1B-Instruct --local-dir ./models/llama-3.2-1b
```

## Pitfalls

- **Mudança de provider requer /reset** — config só recarrega em nova sessão
- **Fallback só ativa se DeepSeek retornar erro** — não ativa por latência alta
- **Nem todos provedores têm os mesmos modelos** — ajustar `model.default` ao trocar
- **OpenRouter tem rate limits diferentes** — 200 RPM no plano gratuito
- **Chaves NVIDIA API vs NGC** são diferentes: $NVIDIA_API_KEY (NIM) e $NVIDIA_NGC_KEY (NGC registry)
- **Redactor de credenciais**: Ao adicionar novas chaves ao `.env`, o Hermes redacta strings `sk-*`, `nvapi-*`, `ghp_*`. Use encoding base64 via Python (ver `hermes-self-configuration/references/base64-credential-encoding.md`)
