#!/usr/bin/env bash
# Health check: Hindsight + vLLM Embedding + vLLM Reranker + recall
# Usage: bash scripts/health-check.sh [bank_name]
# Default bank: hermes

set -euo pipefail

BANK="${1:-hermes}"
PASS=0
FAIL=0

green() { echo -e "\033[32m✅ $1\033[0m"; }
red()   { echo -e "\033[31m❌ $1\033[0m"; }

echo "═══ RAG Pipeline Health Check ═══"
echo "Bank: $BANK"
echo

# 1. Hindsight health
echo "--- Hindsight API ---"
HEALTH=$(curl -sf http://localhost:8888/health 2>/dev/null || true)
if echo "$HEALTH" | grep -q '"healthy"'; then
  green "Hindsight API saudável"
  PASS=$((PASS+1))
else
  red "Hindsight API falhou: $HEALTH"
  FAIL=$((FAIL+1))
fi

# 2. Hindsight database
if echo "$HEALTH" | grep -q '"connected"'; then
  green "Database conectado"
  PASS=$((PASS+1))
else
  red "Database desconectado"
  FAIL=$((FAIL+1))
fi

# 3. vLLM Embedding
echo "--- vLLM Embedding ---"
EMBED=$(curl -sf http://localhost:8000/v1/models 2>/dev/null || true)
if echo "$EMBED" | grep -q "Qwen3-Embedding"; then
  green "vLLM Embedding GPU:0 online"
  PASS=$((PASS+1))
else
  red "vLLM Embedding GPU:0 offline"
  FAIL=$((FAIL+1))
fi

# 4. vLLM Reranker
echo "--- vLLM Reranker GPU:1 ---"
RERANK=$(curl -sf http://localhost:8001/v1/models 2>/dev/null || true)
if echo "$RERANK" | grep -q "Qwen3-Reranker"; then
  green "vLLM Reranker GPU:1 online"
  PASS=$((PASS+1))
else
  red "vLLM Reranker GPU:1 offline"
  FAIL=$((FAIL+1))
fi

# 5. Hindsight bank exists
echo "--- Banco Hindsight ---"
BANKS=$(curl -sf http://localhost:8888/v1/default/banks 2>/dev/null || true)
if echo "$BANKS" | grep -q "\"bank_id\":\"$BANK\""; then
  green "Banco '$BANK' existe"
  PASS=$((PASS+1))
else
  red "Banco '$BANK' não encontrado"
  FAIL=$((FAIL+1))
fi

# 6. Recall test
echo "--- Recall Test ---"
RECALL=$(curl -sf -X POST "http://localhost:8888/v1/default/banks/$BANK/memories/recall" \
  -H "Content-Type: application/json" \
  -d '{"query":"teste de saudabilidade do sistema","k":1}' 2>/dev/null || true)
if echo "$RECALL" | grep -q '"results"'; then
  COUNT=$(echo "$RECALL" | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('results',[])))" 2>/dev/null || echo "0")
  green "Recall funcional ($COUNT resultados)"
  PASS=$((PASS+1))
else
  red "Recall falhou"
  FAIL=$((FAIL+1))
fi

# 7. Reranker test
echo "--- Reranker Test ---"
RERANK_TEST=$(curl -sf -X POST http://localhost:8001/rerank \
  -H "Content-Type: application/json" \
  -d '{"model":"Qwen/Qwen3-Reranker-8B","query":"teste","documents":["documento um","documento dois"],"top_n":2}' 2>/dev/null || true)
if echo "$RERANK_TEST" | grep -q '"results"'; then
  green "Reranker GPU:1 funcional"
  PASS=$((PASS+1))
else
  red "Reranker GPU:1 falhou"
  FAIL=$((FAIL+1))
fi

echo
echo "═══ Resultado: $PASS passaram, $FAIL falharam ═══"
exit $FAIL
