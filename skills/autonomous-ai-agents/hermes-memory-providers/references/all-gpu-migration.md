# ALL-GPU Migration Notes

## Migration Path: CPU BGE 384d → GPU Qwen3 4096d

### What Changed

| Before | After |
|---|---|
| BGE local 384 dims (CPU) | Qwen3-Embedding-8B 4096d (GPU 0 via vLLM) |
| pgvector HNSW index | pgvectorscale DiskANN (5 indexes, num_neighbors=50) |
| `HINDSIGHT_API_EMBEDDINGS_PROVIDER=local` (unset) | `HINDSIGHT_API_EMBEDDINGS_PROVIDER=openai` → vLLM API |
| DB user `hmem` / `hmem_pass_2024` | DB user `hindsight` / `Hindsight123` |
| Hindsight `:latest-slim` (falhou) | Hindsight `:latest` (full, com sentence-transformers) |
| `HINDSIGHT_API_RERANKER_PROVIDER=local` | Removido (reranker agora na GPU 1) |

### Pitfalls Encountered

#### 1. slim image lacks sentence-transformers
`ImportError: sentence-transformers is required for LocalSTCrossEncoder`
Even without setting `HINDSIGHT_API_RERANKER_PROVIDER=local`, the Hindsight API tries to initialize the local reranker by default. **Fix**: use `:latest` (full image).

#### 2. 4096d requires pgvectorscale
`RuntimeError: Embedding dimension 4096 on memory_units exceeds pgvector HNSW index limit of 2000`
pgvector HNSW maxes out at 2000 dims. **Fix**: install pgvectorscale 0.9.0 `.deb` + set `HINDSIGHT_API_VECTOR_EXTENSION=pgvectorscale`.

#### 3. Secret redaction mangles docker -e flags
The Hermes security scanner replaces `sk-...` patterns in terminal output AND in command strings passed to terminal(). A literal `HINDSIGHT_API_LLM_API_KEY=sk-real-key` in a `docker run -e` command gets written as `sk-***`. **Fix**: use `--env-file /tmp/hindsight.env` (write_file is not subject to redaction at the source).

#### 4. Database connections must be killed before DROP DATABASE
`ERROR: database "hindsight" is being accessed by other users` (the Hindsight container itself holds connections). **Fix**: terminate backends first, then DROP.

### Key Env Vars (ALL-GPU config)

```
HINDSIGHT_API_LLM_PROVIDER=deepseek
HINDSIGHT_API_LLM_API_KEY=sk-...
HINDSIGHT_API_LLM_MODEL=deepseek-v4-flash
HINDSIGHT_API_DATABASE_BACKEND=postgresql
HINDSIGHT_API_DATABASE_URL=postgresql+psycopg2://hindsight:Hindsight123@host.docker.internal:5432/hindsight
HINDSIGHT_API_EMBEDDINGS_PROVIDER=openai
HINDSIGHT_API_EMBEDDINGS_OPENAI_BASE_URL=http://host.docker.internal:8000/v1
HINDSIGHT_API_EMBEDDINGS_OPENAI_MODEL=Qwen/Qwen3-Embedding-8B
HINDSIGHT_API_EMBEDDINGS_DIMENSIONS=4096
```

### pgvectorscale Installation

```bash
curl -sL -o /tmp/pgvectorscale.zip \
  https://github.com/timescale/pgvectorscale/releases/download/0.9.0/pgvectorscale-0.9.0-pg17-amd64.zip
cd /tmp && unzip -o pgvectorscale.zip
sudo dpkg -i pgvectorscale-postgresql-17_0.9.0-Linux_amd64.deb
sudo -u postgres psql -d hindsight -c "CREATE EXTENSION IF NOT EXISTS vectorscale CASCADE;"
```
