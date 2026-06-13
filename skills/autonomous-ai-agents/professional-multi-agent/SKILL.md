---
name: professional-multi-agent
description: "Workflows multi-agente profissionais: delegação paralela, orquestração de tarefas complexas, coordenação de agentes especializados."
version: 1.0.0
author: Hermes Agent (Bruno's professional setup)
tags: [multi-agent, delegation, orchestration, parallel-workflows]
related_skills: [daily-ops, plan, systematic-debugging]
permissions:
  - delegation:spawn  # delegate_task para subagentes
  - terminal:execute
  - network:connect
  - filesystem:read
platforms: [linux]
---

# Professional Multi-Agent Workflows

Workflows de delegação e orquestração multi-agente para tarefas complexas. Usa delegate_task com batch para paralelizar.

## Arquitetura

```
         Agente Principal (Hermes)
         Orquestrador / Supervisor
               │
    delegate_task(tasks=[...])
               │
    ┌─────┬────┼────┬─────┐
    │ A   │ B  │ C  │ D  │  ← até 3 em paralelo
    └──┬──┴──┬─┴──┬─┴──┬──┘
       │    │    │    │
       ▼    ▼    ▼    ▼
         Síntese Final
```

## Padrões

### 1. Pesquisa 360° (3 agentes)

```python
from hermes_tools import delegate_task

tasks = [
    {"goal": "Pesquisar papers e artigos acadêmicos sobre <tópico>",
     "context": "Foco em arquitetura e implementações. Retornar 3-5 referências.",
     "toolsets": ["web"]},
    {"goal": "Pesquisar ferramentas open-source GitHub sobre <tópico>",
     "context": "Repositórios ativos, estrelas, licença. Top 3.",
     "toolsets": ["web"]},
    {"goal": "Analisar viabilidade para 2x RTX 3090, CUDA 13.3, Debian 13",
     "context": "VRAM 24GB, Docker. Prós/contras e requisitos.",
     "toolsets": ["web"]}
]
resultados = delegate_task(tasks=tasks)
```

### 2. Code Review (2 agentes)

```python
tasks = [
    {"goal": "Revisar segurança: injeção, credenciais, permissões",
     "context": "Caminho: <path>.",
     "toolsets": ["terminal", "file"]},
    {"goal": "Revisar qualidade: boas práticas, performance",
     "context": "Caminho: <path>.",
     "toolsets": ["terminal", "file"]}
]
```

### 3. Debug Distribuído

```python
tasks = [
    {"goal": "Analisar logs do container <nome>",
     "context": "docker logs --tail 100. Buscar padrões de erro.",
     "toolsets": ["terminal"]},
    {"goal": "Verificar config e dependências",
     "context": "Config, env vars, portas, processos.",
     "toolsets": ["terminal", "file"]},
    {"goal": "Testar conectividade entre componentes",
     "context": "curl endpoints, health checks.",
     "toolsets": ["terminal"]}
]
```

## Regras

1. Máximo 3 tarefas paralelas por batch
2. Passar contexto completo em cada task
3. Verificar side effects (arquivos criados, HTTP) — agentes podem reportar sucesso falso
4. Sintetizar resultados, não concatenar
- Verificar side effects (arquivos criados, HTTP) — agentes podem reportar sucesso falso
- Para OpenCode CLI, o binário pode estar em `/opt/OpenCode/` (Desktop app GUI) — usar `npx opencode-ai` para o CLI real (ver `references/opencode-via-npx.md`)

## Pitfalls

- Agentes não têm memória da conversa. Passar tudo em context.
- Verificar arquivos/endpoints que agentes dizem ter criado/modificado.
- Agentes respondem em inglês a menos que o context peça pt-BR.
