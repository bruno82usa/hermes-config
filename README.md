# 🤖 Hermes Config — Bruno's AI Infrastructure

Configuração completa do [Hermes Agent](https://hermes-agent.nousresearch.com) rodando em **Debian 13** com **2x RTX 3090**.

## Stack

| Componente | Tecnologia |
|---|---|
| **LLM** | DeepSeek v4-flash (+ OpenRouter fallback) |
| **Memória** | Hindsight ALL-GPU (Qwen3-Embedding GPU:0 + Reranker GPU:1) |
| **Banco Vetorial** | PostgreSQL 17 + pgvectorscale DiskANN (4096d) |
| **Infra** | Docker, NVIDIA NGC, CUDA 13.3 |
| **Coding Agent** | OpenCode CLI + GitHub CLI |

## Skills Custom (9)

| Skill | Categoria | Função |
|---|---|---|
| `hermes-memory-providers` | AI Agents | Integração Hindsight ALL-GPU |
| `hermes-self-configuration` | AI Agents | Auto-configuração do Hermes |
| `professional-multi-agent` | AI Agents | Delegação paralela multi-agente |
| `rag-pipeline-hindsight` | MLOps | Pipeline RAG completo |
| `infra-health-check` | DevOps | Health check em 5 fases |
| `daily-ops` | Produtividade | Rotinas diárias |
| `nvidia-ngc-integration` | MLOps | Containers NVIDIA NGC |
| `github-cli-automation` | GitHub | Automação gh CLI |
| `multi-provider-resilience` | MLOps | Fallback multi-provider |

## Estrutura

```
hermes-config/
├── skills/              # Skills custom (9 locais)
│   ├── autonomous-ai-agents/
│   ├── devops/
│   ├── github/
│   ├── mlops/
│   └── productivity/
├── cron/                # Scripts dos cron jobs
├── config/              # Templates de configuração
├── .env.example         # Placeholders de API keys
└── README.md
```

## Como Usar

```bash
# Clone nas suas skills
cp -r skills/* ~/.hermes/profiles/bruno/skills/

# Configure secrets
cp .env.example ~/.hermes/profiles/bruno/.env
# edite .env com suas chaves reais

# Reinicie o Hermes
hermes /reset
```

Feito por [@bruno82usa](https://github.com/bruno82usa)
