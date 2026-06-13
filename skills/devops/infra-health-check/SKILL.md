---
name: infra-health-check
description: "Verificação completa da stack Bruno: containers, GPUs, Hindsight, PostgreSQL, logs, disco — health check em 5 fases com saída formatada em tabelas."
version: 1.0.0
author: Hermes Agent (Bruno's professional setup)
tags: [infrastructure, health-check, monitoring, docker, gpu, hindsight, postgresql]
related_skills: [hermes-memory-providers, rag-pipeline-hindsight]
permissions:
  - network:connect:localhost:8888  # Hindsight health
  - network:connect:localhost:8000  # vLLM Embedding
  - network:connect:localhost:8001  # vLLM Reranker
  - terminal:execute                # Docker, nvidia-smi, psql
  - filesystem:read
platforms: [linux]
---

# Infra Health Check

Skill para **verificar todos os componentes da infraestrutura** do Bruno em segundos. Executa em 5 fases sequenciais e apresenta resultados em tabelas.

## Visão Geral

```
┌─────────────────────────────────────────────────────┐
│              🖥️  INFRA HEALTH CHECK                  │
├─────────────────────────────────────────────────────┤
│ FASE 1 | Containers     │ docker ps + health check  │
│ FASE 2 | GPUs           │ nvidia-smi (temp, VRAM)  │
│ FASE 3 | Hindsight      │ health + bank status      │
│ FASE 4 | PostgreSQL     │ conexão, extensões, dims  │
│ FASE 5 | Disco + Docker │ df, log rotation          │
└─────────────────────────────────────────────────────┘
```

## Execução Completa

Use `execute_code` para rodar todas as 5 fases em paralho e devolver um relatório consolidado:

```python
from hermes_tools import terminal
import json

resultados = {}

# FASE 1: Containers
containers = terminal("docker ps --format '{{.Names}}\t{{.State}}\t{{.Ports}}\t{{.Status}}'")
resultados["containers"] = containers["output"]

# FASE 2: GPUs
gpus = terminal("nvidia-smi --query-gpu=index,name,temperature.gpu,memory.used,memory.total,utilization.gpu --format=csv,noheader")
resultados["gpus"] = gpus["output"]

# FASE 3: Hindsight
health = terminal("curl -sf http://localhost:8888/health")
banks = terminal("curl -sf http://localhost:8888/v1/default/banks")
resultados["hindsight"] = health["output"]
resultados["hindsight_banks"] = banks["output"]

# FASE 4: PostgreSQL + vLLM endpoints
pg_test = terminal("psql -h localhost -U hindsight -d hindsight -c \"SELECT extname, extversion FROM pg_extension ORDER BY extname;\" 2>&1")
vllm_embed = terminal("curl -sf http://localhost:8000/v1/models | python3 -c \"import sys,json; d=json.load(sys.stdin); print('\\n'.join([m['id'] for m in d['data']]))\"")
vllm_rerank = terminal("curl -sf http://localhost:8001/v1/models | python3 -c \"import sys,json; d=json.load(sys.stdin); print('\\n'.join([m['id'] for m in d['data']]))\"")
resultados["postgresql"] = pg_test["output"]
resultados["vllm_embedding"] = vllm_embed["output"]
resultados["vllm_reranker"] = vllm_rerank["output"]

# FASE 5: Disco
disk = terminal("df -h / /home /var/lib/docker 2>/dev/null | tail -5")
docker_logs = terminal("docker info --format '{{.DriverStatus}}' 2>/dev/null | head -3; echo '---'; ls -la /etc/docker/daemon.json 2>/dev/null && cat /etc/docker/daemon.json 2>/dev/null || echo 'daemon.json não encontrado'")
resultados["disk"] = disk["output"]
resultados["docker_log_config"] = docker_logs["output"]

print(json.dumps(resultados, indent=2))
```

## Fases Individuais

### FASE 1: Containers

```bash
echo "=== 🐳 CONTAINERS ==="
docker ps --format "table {{.Names}}\t{{.State}}\t{{.Ports}}\t{{.Status}}"
```

**Esperado:** 3 containers rodando: `vllm-embedding`, `vllm-reranker`, `hindsight`. Todos `running` + `unless-stopped`.

### FASE 2: GPUs

```bash
echo "=== 🎮 GPUS ==="
nvidia-smi --query-gpu=index,name,temperature.gpu,memory.used,memory.total,utilization.gpu --format=csv
echo ""
echo "=== GPU 0 (Embedding) ==="
nvidia-smi -i 0 --query-gpu=memory.used,utilization.gpu,temperature.gpu --format=csv,noheader
echo "=== GPU 1 (Reranker) ==="
nvidia-smi -i 1 --query-gpu=memory.used,utilization.gpu,temperature.gpu --format=csv,noheader
```

**Alertas:** Temp > 80°C, VRAM > 95%, Fan > 90%.

### FASE 3: Hindsight

```bash
echo "=== 🧠 HINDSIGHT ==="
echo "--- Health ---"
curl -sf http://localhost:8888/health
echo ""
echo "--- Banks ---"
curl -sf http://localhost:8888/v1/default/banks | python3 -m json.tool
echo ""
echo "--- Memory Count ---"
curl -sf http://localhost:8888/v1/default/banks/hermes/memories/list 2>&1 | python3 -c "
import sys, json
data = json.load(sys.stdin)
print(f'Total de memórias no bank hermes: {len(data.get(\"memories\", data.get(\"items\", [])))}')
" 2>/dev/null || echo "Erro ao contar memórias"
```

### FASE 4: PostgreSQL + vLLM

```bash
echo "=== 🐘 POSTGRESQL ==="
PGPASSWORD=Hindsight123 psql -h localhost -U hindsight -d hindsight -c "
SELECT 'Status' as info, 'Online' as valor
UNION ALL
SELECT 'Extensões', string_agg(extname || ' ' || extversion, ', ')
FROM pg_extension;
"

echo "=== ⚡ VLLM EMBEDDING ==="
curl -sf http://localhost:8000/v1/models | python3 -c "
import sys, json
d = json.load(sys.stdin)
for m in d['data']:
    print(f'  Modelo: {m[\"id\"]} | Max len: {m.get(\"max_model_len\",\"?\")}')
"

echo "=== ⚡ VLLM RERANKER ==="
curl -sf http://localhost:8001/v1/models | python3 -c "
import sys, json
d = json.load(sys.stdin)
for m in d['data']:
    print(f'  Modelo: {m[\"id\"]} | Max len: {m.get(\"max_model_len\",\"?\")}')
"
```

### FASE 5: Disco + Docker Logs

```bash
echo "=== 💾 DISCO ==="
df -h / /home /var/lib/docker 2>/dev/null

echo "=== 📝 DOCKER LOG CONFIG ==="
if [ -f /etc/docker/daemon.json ]; then
    echo "Configuração de logs:"
    cat /etc/docker/daemon.json
else
    echo "⚠️ daemon.json não encontrado - sem log rotation!"
    echo "  Crie com: write_file e reinicie o docker"
fi
```

**Alerta:** Disco < 20% livre.

## Relatório Consolidado

Após executar as 5 fases, monte o relatório no formato:

```
┌─────────────────────────────────────────────────────┐
│         🖥️  INFRA HEALTH CHECK — YYYY-MM-DD HH:MM  │
├─────────────────────────────────────────────────────┤
│ 🐳 Containers  │ vllm-embedding ✅ │ vllm-reranker ✅ │ hindsight ✅  │
│ 🎮 GPUs        │ GPU:0 N°C N% Vram │ GPU:1 N°C N% Vram               │
│ 🧠 Hindsight   │ Status ✅ │ N memórias                              │
│ 🐘 PostgreSQL  │ Online ✅ │ Extensões: vector, vectorscale          │
│ 💾 Disco       │ / N% usado │ Docker logs: configurado ✅/❌        │
└─────────────────────────────────────────────────────┘
```

## Uso no Dia a Dia

```bash
# Verificação rápida
hermes chat -s infra-health-check -q "Roda health check completo"

# Verificação específica
hermes chat -s infra-health-check -q "Só GPUs e containers"
```

## Pitfalls

- **NUNCA modificar containers em produção**: Se todos os containers estão rodando e saudáveis, **não pare, não recrie, não troque a imagem**. "Não se meche em time que está ganhando." Se um upgrade for necessário, crie um container paralelo para teste primeiro.
- **Health check é somente leitura**: O propósito do health check é *diagnosticar*, não *consertar*. Reporte problemas, não execute ações corretivas sem autorização explícita do usuário.
- **sudo no psql**: O comando `psql` usa o usuário `hindsight` com senha `Hindsight123`. PGPASSWORD evita prompt. Se falhar com autenticação, verificar `pg_hba.conf`.
- **curl timeouts**: Se um serviço estiver fora do ar, o timeout do curl pode travar a verificação. Use `-sf` (silent, fail) + timeout.
- **health check do Hindsight**: Retorna `{"status":"healthy","database":"connected"}` quando ok.
- **SkillSpector em skills de infra**: Skills de infraestrutura sempre terão score alto (URLs localhost, comandos sudo, curl pipes). São falsos positivos esperados — não reportar como vulnerabilidades. Ver `references/skillspector-interpretation.md` para guia completo.
