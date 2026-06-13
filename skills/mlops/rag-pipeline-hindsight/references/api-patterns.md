# API Patterns — Hindsight + Reranker

## Hindsight Recall

### Request
```bash
curl -s -X POST http://localhost:8888/v1/default/banks/hermes/memories/recall \
  -H "Content-Type: application/json" \
  -d '{"query":"<query transformada>","k":8}'
```

### Response Structure
```json
{
  "results": [
    {
      "id": "uuid",
      "text": "conteúdo do fato extraído",
      "type": "observation|world|experience",
      "entities": ["Entidade1", "Entidade2"],
      "mentioned_at": "timestamp"
    }
  ],
  "entities": {
    "Entidade1": {"entity_id": "uuid", "canonical_name": "Entidade1"}
  }
}
```

### Pitfalls
- O parâmetro chama-se `k` para número de resultados
- Pode retornar mais resultados se houver empates de score
- Entidades vêm em formato de dicionário, não array

## Reranker GPU:1

### Request
```bash
curl -s -X POST http://localhost:8001/rerank \
  -H "Content-Type: application/json" \
  -d '{
    "model": "Qwen/Qwen3-Reranker-8B",
    "query": "<query>",
    "documents": ["doc1", "doc2", ...],
    "top_n": 4
  }'
```

### Response
```json
{
  "id": "score-xxx",
  "model": "Qwen/Qwen3-Reranker-8B",
  "usage": {"prompt_tokens": N, "total_tokens": N},
  "results": [
    {"index": 0, "document": {"text": "..."}, "relevance_score": 0.0560},
    {"index": 1, "document": {"text": "..."}, "relevance_score": 0.0418}
  ]
}
```

### Pitfalls
- `index` no resultado refere-se à posição no array `documents` original
- scores NÃO são normalizados (0-1 mas não somam 1)
- Model name precisa ser exato: `Qwen/Qwen3-Reranker-8B`
- O endpoint `/rerank` (não `/v1/rerank` nem `/v1/score`)
- Viés observado: docs mencionando "reranker" ou "cross-encoder" podem ganhar score mais alto se a query contiver termos similares

## Hindsight Store Memory

### Request
```bash
curl -s -X POST http://localhost:8888/v1/default/banks/hermes/memories \
  -H "Content-Type: application/json" \
  -d '{
    "items": [{"content": "<texto>", "document_id": "<id_opcional>"}],
    "async": false
  }'
```

### Response
```json
{
  "success": true,
  "items_count": 1,
  "usage": {"input_tokens": N, "output_tokens": N, "total_tokens": N}
}
```

### Pitfalls
- Items é um ARRAY obrigatório no campo `items`, não `text` solto
- Cada item tem campo `content` (não `text`)
- `document_id` causa upsert: se existir, deleta doc anterior e recria
- Com `async: false`, a resposta só volta após DeepSeek processar e extrair fatos
- Com `async: true` (padrão), retorna imediatamente e processa em background
- DeepSeek gasta tokens para extrair fatos (~3K in + ~1.5K out por item)
