# Production Audit Checklist — RAG Infrastructure

Checklist reutilizável de 5 fases para auditoria de produção de uma stack RAG local com PostgreSQL + Hindsight + vLLM.

## FASE 1: Deep Clean
- [ ] Remover containers obsoletos: `docker rm -f <nome>`
- [ ] Remover imagens não utilizadas: `docker rmi <imagem>` (recupera GBs)
- [ ] Limpar `/tmp/*.json`, caches de sessões anteriores
- [ ] `sudo apt clean && sudo apt autoremove -y`
- [ ] Verificar espaço em disco: `df -h /`

## FASE 2: Hardware & Drivers
- [ ] Baseline temperatura GPU (repouso < 50°C): `nvidia-smi`
- [ ] Baseline energia GPU (repouso < 30W)
- [ ] Isolamento VRAM: embedding na GPU 0, reranker na GPU 1
- [ ] `--gpu-memory-utilization` do vLLM configurado (0.9 padrão)
- [ ] Verificar OOM risk: VRAM livre > 2GB por GPU

## FASE 3: Banco Vetorial
- [ ] Extensão pgvector ativa: `\dx` no psql
- [ ] Versão do pgvector: deve ser 0.5+ (0.8 recomendado)
- [ ] Dimensão do embedding: `SELECT vector_dims(embedding) FROM memory_units LIMIT 1;`
- [ ] `pg_hba.conf`: rede Docker em `scram-sha-256`, não `md5`
- [ ] `data_directory` em NVMe: `SHOW data_directory;`
- [ ] `listen_addresses` restrito ao necessário: `SHOW listen_addresses;`

## FASE 4: Serviços & Contêineres
- [ ] Restart policies: `docker inspect <container> --format '{{.HostConfig.RestartPolicy.Name}}'`
  - [ ] vllm-embedding → `unless-stopped`
  - [ ] vllm-reranker → `unless-stopped`
  - [ ] hindsight → `unless-stopped`
- [ ] Log rotation Docker configurado: `/etc/docker/daemon.json`
  ```json
  { "log-driver": "json-file", "log-opts": { "max-size": "50m", "max-file": "3" } }
  ```
- [ ] Tamanho dos logs: `ls -lh $(docker inspect --format '{{.LogPath}}' <container>)`
- [ ] Variáveis de ambiente críticas revisadas (sem chaves expostas)
- [ ] `--add-host=host.docker.internal:host-gateway` presente nos containers que acessam o host

## FASE 5: Teste E2E
- [ ] Ingestão de memória 500+ tokens: `POST /v1/default/banks/hermes/memories`
- [ ] Verificar tokens de saída do LLM (confirma que DeepSeek/OpenAI está autenticado)
- [ ] Recall por pergunta: `POST /v1/default/banks/hermes/memories/recall`
- [ ] Rerank manual via vLLM GPU:1: `POST localhost:8001/v1/rerank`
- [ ] Pipeline completo: Hindsight recall → vLLM rerank → resultado final

## Comandos Rápidos

```bash
# GPU
nvidia-smi --query-gpu=index,name,temperature.gpu,power.draw,memory.used,memory.total --format=csv,noheader

# Restart policies
for c in vllm-embedding vllm-reranker hindsight; do
  echo "$c: $(docker inspect $c --format '{{.HostConfig.RestartPolicy.Name}}')"
done

# Dimensão do embedding
PGPASSWORD=*** psql -h localhost -U hmem -d hindsight -c \
  "SELECT vector_dims(embedding), count(*) FROM memory_units GROUP BY vector_dims(embedding);"

# Log rotation
cat /etc/docker/daemon.json
