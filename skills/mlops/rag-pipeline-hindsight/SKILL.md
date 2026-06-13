---
name: rag-pipeline-hindsight
description: "Pipeline RAG completo: Hermes → Hindsight (recall) → Qwen3-Reranker GPU:1 → Resposta final com DeepSeek"
version: 2.0.0
author: Hermes Agent
tags: [hindsight, rag, reranker, qwen3, pipeline, autonomy, via-pesada]
related_skills: [hermes-memory-providers]
permissions:
  - network:connect:localhost:8888  # Hindsight API
  - network:connect:localhost:8000  # vLLM Embedding
  - network:connect:localhost:8001  # vLLM Reranker
  - terminal:execute                # Scripts auxiliares
  - filesystem:read                 # Referências e templates
---

# Pipeline RAG — Hermes + Hindsight + Re-Ranker

## Arquitetura

```
Pergunta do usuário
     │
     ▼ (autonomia: SEMPRE consultar Hindsight primeiro)
┌────────────────┐
│  Hindsight     │  POST /v1/default/banks/hermes/memories/recall
│  Recall (top-k)│  4096d embeddings, pgvectorscale DiskANN
└───────┬────────┘
        │ resultados brutos
        ▼
┌────────────────┐  ← VIA PESADA: acionar SE for sobre:
│  Qwen3-Reranker│     • arquitetura de software/código-fonte
│  GPU:1 :8001   │     • Project Kronos / CardioIA
└───────┬────────┘     • resultados técnicos ambíguos
        │ relevance_score da GPU 1 = juiz absoluto
        ▼
┌────────────────┐
│  DeepSeek      │  Resposta final com contexto enriquecido
│  v4-flash      │
└────────────────┘
```

## Diretiva de Autonomia (Obrigatória)

**Você NÃO deve esperar o usuário pedir explicitamente para consultar a memória.** Sempre que um prompt envolver:

1. Projetos passados, presentes ou futuros (configs de servidor, arquitetura de banco, chaves, rotinas)
2. Preferências do usuário sobre código, ferramentas ou infraestrutura
3. Continuidade de conversas de dias anteriores ou informações ambíguas

**Ação imediata:** Disparar silenciosamente o Hindsight para recuperar o contexto ANTES de começar a formular a resposta. Se dados forem técnicos ou extensos, acionar o Reranker GPU:1 para filtrar ruído.

## Trigger Conditions

| Gatilho | Ação |
|---|---|
| Pergunta sobre infra/config | Recall Hindsight → se técnico, rerank |
| "O que fizemos sobre X?" | Recall Hindsight obrigatório |
| "Como configuramos Y?" | Recall Hindsight obrigatório |
| Project Kronos / CardioIA | Recall + **rerank GPU:1 obrigatório** (Via Pesada) |
| Arquitetura de software | Recall + **rerank GPU:1 obrigatório** |
| Resultados ambíguos do recall | Rerank GPU:1 para desempatar |
| 0 resultados do recall | Responder sem contexto (não inventar) |

## Query Transformation (Princípio Crítico)

**NUNCA envie a pergunta bruta do usuário para o embedding.** Reescreva para uma query declarativa rica em palavras-chave:

- ❌ "o que eu falei sobre aquele projeto ontem?"
- ✅ "Detalhes, decisões e atualizações sobre o projeto X discutidos recentemente"

Isso melhora drasticamente a qualidade do recall semântico.

## Pipeline Completo (Passo a Passo)

### 1. Query Transformation + Hindsight Recall

```python
from hermes_tools import terminal
import json

# Sempre transformar a query
query_transformada = "reescrita declarativa rica em keywords"

recall = terminal(f"""curl -s -X POST http://localhost:8888/v1/default/banks/hermes/memories/recall \
  -H "Content-Type: application/json" \
  -d '{{"query":"{query_transformada}","k":8}}'""")

recall_data = json.loads(recall["output"])
results = recall_data.get("results", [])

# Extrair entidades para contexto
entities = recall_data.get("entities", {})
```

Parâmetros: `k=8` (bom para dar variedade ao reranker).

### 2. Via Pesada — Reranker GPU:1 (Condicional)

Só executar se os resultados forem técnicos, ambíguos, ou sobre os tópicos de Via Pesada.

```python
documents = [r["text"] for r in results]
rerank_payload = {
    "model": "Qwen/Qwen3-Reranker-8B",
    "query": query_transformada,
    "documents": documents,
    "top_n": 4
}

rerank = terminal(f"""curl -s -X POST http://localhost:8001/rerank \
  -H "Content-Type: application/json" \
  -d '{json.dumps(rerank_payload)}'""")

reranked = json.loads(rerank["output"]).get("results", [])
# relevance_score da GPU 1 = decisão final
context = "\n\n".join([documents[r["index"]] for r in reranked])
```

**Sempre usar `json.dumps()` para serializar payloads** — NUNCA interpolar strings com f-strings ou bash para montar JSONs.

### 3. Resposta com Contexto Enriquecido

Usar os textos rerankeados como contexto adicional. Incluir bloco:

```
Contexto de memórias anteriores:
<resultados>
```

## Validação — 5 Fases de Auditoria

Executar ao implantar ou após mudanças na stack:

### FASE 1: Ingestão e Destilação
```bash
curl -s -X POST http://localhost:8888/v1/default/banks/hermes/memories \
  -H "Content-Type: application/json" \
  -d '{"items":[{"content":"texto de teste com múltiplos fatos"}],"async":false}'
```
Verificar extração: `GET /v1/default/banks/hermes/memories/list`

### FASE 2: Recall Semântico (Sem Keyword)
Usar query com vocabulário DIFERENTE do texto original. Verificar se os fatos corretos aparecem no topo.

### FASE 3: Resiliência a Alucinações
Perguntar sobre projeto inexistente ("Projeto Apollo"). Verificar ZERO falsos positivos.

### FASE 4: Via Pesada (Reranker)
Recall 10 docs → rerank GPU:1 → verificar Top 3 + relevance_scores.

### FASE 5: Autonomia
Confirmar que a diretiva de consulta automática está ativa em memória.

## Notas Importantes

- O reranker espera `query` (string) e `documents` (array de strings) no endpoint `/rerank`
- `top_n` controla quantos retornar (default: todos). Recomendado: 4.
- `relevance_score` é float 0-1 (não normalizado) — GPU:1 é juiz absoluto
- O `.env` deve conter `HINDSIGHT_URL=http://localhost:8888` e `HINDSIGHT_MODE=remote`
- ALL-GPU: embeddings 100% na GPU 0 (Qwen3-Embedding 4096d), reranker na GPU 1
- Banco: PostgreSQL 17 + pgvectorscale DiskANN, usuário `hindsight`
- A skill `hermes-memory-providers` tem a documentação oficial de configuração e a Diretiva de Autonomia
