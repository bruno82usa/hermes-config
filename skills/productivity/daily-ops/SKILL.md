---
name: daily-ops
description: "Rotinas diárias do Bruno: início de expediente, verificação de pendências, organização de tarefas, e encerramento do dia."
version: 1.0.0
author: Hermes Agent (Bruno's professional setup)
tags: [operations, daily-routine, productivity, workflow]
related_skills: [infra-health-check, hermes-memory-providers, rag-pipeline-hindsight, plan]
permissions:
  - terminal:execute        # Docker, health checks
  - network:connect:localhost:8888  # Hindsight
  - filesystem:read
platforms: [linux]
---

# Daily Ops — Rotinas Diárias do Bruno

Skill para **gerenciar o expediente**: início do dia, pausas, organização de tarefas e encerramento. Integra health check, verificação de pendências e planejamento.

## 📥 Início de Expediente (Bom Dia!)

Quando o Bruno disser "bom dia" ou "vamos começar", executar automaticamente:

### Passo 1: Health Check Rápido

```python
from hermes_tools import terminal, session_search
import json

containers = terminal("docker ps --format '{{.Names}} {{.State}}'")
container_lines = [l for l in containers["output"].split("\n") if l.strip()]
all_ok = all("running" in l for l in container_lines)
gpu_temp = terminal("nvidia-smi -i 0 --query-gpu=temperature.gpu --format=csv,noheader")

print(f"Containers: {'🟢 OK' if all_ok else '🔴 PROBLEMA'}")
print(f"GPU Temp: {gpu_temp['output'].strip()}°C")

if not all_ok:
    print("⚠️  Nem todos containers rodando — execute health check completo com a skill infra-health-check")
```

### Passo 2: Verificar Últimas Pendências

```python
from hermes_tools import session_search

recent = session_search()
if recent.get("results"):
    for s in recent["results"]:
        print(f"📋 {s.get('title','?')} — {s.get('preview','')[:80]}")
```

### Passo 3: Plano do Dia

Após health check + pendências, perguntar o plano.

## 📤 Encerramento

### Passo 1: Estado Final

```bash
echo "=== 🐳 Containers ==="
docker ps --format "table {{.Names}}\t{{.State}}\t{{.Status}}"
echo ""
echo "=== 🧠 Hindsight ==="
curl -sf http://localhost:8888/health
```

### Passo 2: Salvar Checkpoint

Salvar em memória o estado e o que ficou pendente.

### Passo 3: Resumo do Dia

Apresentar: o que foi feito, o que ficou pendente, estado da infra.

## 🔄 Pós-Restart do Servidor

1. Verificar Docker
2. Verificar PostgreSQL
3. `docker start vllm-embedding vllm-reranker hindsight` se necessário
4. Verificar GPUs
5. Health check do Hindsight
6. Relatório

## ⚠️ Princípio Fundamental

**NUNCA modificar containers em produção.** Se todos os serviços estão rodando e saudáveis, não pare, não recrie, não troque imagens. "Não se meche em time que está ganhando." Health check é diagnóstico, não ação corretiva.

Para upgrades ou testes, usar containers paralelos com nomes diferentes (ex: `vllm-embedding-ngc` em vez de substituir `vllm-embedding`).
