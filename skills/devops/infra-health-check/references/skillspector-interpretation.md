# Interpretação de Resultados do SkillSpector em Skills de Infra

## Contexto

Skills de infraestrutura (health check, deploy, Docker, GPU) **sempre** terão score alto (CRITICAL/100) no SkillSpector. Isso é esperado e NÃO indica vulnerabilidades reais.

## Falsos Positivos Comuns

| Issue | O SkillSpector vê | Realidade |
|---|---|---|
| **E1** — External Transmission | `http://localhost:8888` | Serviço próprio (Hindsight API) |
| **E1** — External Transmission | `http://localhost:8000` | Serviço próprio (vLLM Embedding) |
| **E1** — External Transmission | `http://localhost:8001` | Serviço próprio (vLLM Reranker) |
| **PE2** — Sudo/Root Execution | `sudo systemctl restart pg` | Comando admin documentado |
| **SC2** — External Script Fetching | `curl localhost \| python3 -c` | Parsing de JSON interno |
| **PE3** — Credential Access | `/tmp/hindsight.env` | Documentação de setup |
| **LP4** — Permission not used | Permissão declarada no frontmatter | Analyzer não rastreia curl em markdown |

## Quando se Preocupar

SkillSpector é relevante para **skills de terceiros** (Hub, GitHub, Taps). Para skills próprias de infra:

- **Ignore score/severity** — sempre será CRITICAL
- **Verifique apenas**: LP3 (sem permissions declaradas), SC4 (CVE conhecido), EA1 (agency excessiva)
- **SC2** com URL externa (não localhost) — aí sim é alerta real

## Execução

```bash
cd /tmp/SkillSpector && source .venv/bin/activate
skillspector scan /caminho/da/skill/ --no-llm --format terminal
```

A flag `--no-llm` evita chamadas de API e acelera a análise.
