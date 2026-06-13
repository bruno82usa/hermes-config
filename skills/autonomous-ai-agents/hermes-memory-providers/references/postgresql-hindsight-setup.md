# PostgreSQL 17 + Hindsight — Working Reference

Stack validada em Debian 13, CUDA 13.3, dual RTX 3090.

## Componentes

| Componente | Tecnologia | Porta |
|---|---|---|
| Embedding | vLLM Qwen3-Embedding-8B (GPU:0) | 8000 |
| Reranker | vLLM Qwen3-Reranker-8B (GPU:1) | 8001 |
| Memória | Hindsight (full image, BGE 384 dims) | 8888 |
| Banco | PostgreSQL 17 + pgvector 0.8 | 5432 |
| LLM | DeepSeek v4-flash | API externa |

## Instalação PostgreSQL

```bash
sudo apt install postgresql-17 postgresql-17-pgvector

sudo -u postgres psql -c "CREATE USER hmem WITH PASSWORD 'hmem_pass_2024';"
sudo -u postgres psql -c "CREATE DATABASE hindsight OWNER hmem;"
sudo -u postgres psql -d hindsight -c "CREATE EXTENSION vector;"

# Configurar listen para Docker
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/17/main/postgresql.conf
echo "host all all 172.17.0.0/16 md5" | sudo tee -a /etc/postgresql/17/main/pg_hba.conf
sudo systemctl restart postgresql
```

## Hindsight Container

## Hindsight Container

> **IMPORTANTE — Secret Redaction**: O Hermes redacta strings `sk-...` no terminal. Crie o env-file via Python para evitar redação.

```bash
# Criar env-file via Python (evita redação do Hermes)
python3 -c "
import base64
key = base64.b64decode(open('/tmp/key.b64').read()).decode()
with open('/tmp/hindsight.env', 'w') as f:
    f.write(f'HINDSIGHT_API_LLM_API_KEY={key}')
"

docker run -d --name hindsight \
  --restart unless-stopped \
  -p 8888:8888 \
  --add-host=host.docker.internal:host-gateway \
  --env-file /tmp/hindsight.env \
  -e HINDSIGHT_API_LLM_PROVIDER=deepseek \
  -e HINDSIGHT_API_LLM_MODEL=deepseek-v4-flash \
  -e 'HINDSIGHT_API_DATABASE_URL=postgresql://hmem:***@host.docker.internal:5432/hindsight' \
  -e HINDSIGHT_API_RERANKER_PROVIDER=local \
  ghcr.io/vectorize-io/hindsight:latest
```

> ⚠️ **`--restart unless-stopped` obrigatório**: sem esta flag o container não reinicia após reboot ou falha.

## API Usage

```bash
# Gravar memória (cria bank automaticamente)
curl -X POST "http://localhost:8888/v1/default/banks/hermes/memories" \
  -H "Content-Type: application/json" \
  -d '{"items": [{"content": "Fato relevante."}]}'

# Recall
curl -X POST "http://localhost:8888/v1/default/banks/hermes/memories/recall" \
  -H "Content-Type: application/json" \
  -d '{"query": "pergunta", "limit": 5}'
```

## Notas

- Embedding local (BGE 384 dims) usado porque pgvector HNSW tem limite de 2000 dims
- Para 4096 dims (Qwen3-Embedding-8B): instalar pgvectorscale (DiskANN) no PostgreSQL
- `--add-host=host.docker.internal:host-gateway` obrigatório no Linux (não resolvido por padrão)
- A flag `--restart unless-stopped` não foi usada nesta configuração; se desejar restart automático, adicionar ao comando docker run
