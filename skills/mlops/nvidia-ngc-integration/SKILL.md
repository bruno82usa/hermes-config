---
name: nvidia-ngc-integration
description: "Workflow para baixar e executar containers NVIDIA NGC (vLLM, NIM, CUDA) — login no NVCR.io, gerenciamento de imagens e deploy com GPU."
version: 1.0.0
author: Hermes Agent (Bruno's setup)
tags: [nvidia, ngc, nvcr, docker, gpu, vllm, nims]
related_skills: [serving-llms-vllm, hermes-memory-providers]
permissions:
  - terminal:execute
  - network:connect:nvcr.io
  - filesystem:read
platforms: [linux]
---

# NVIDIA NGC Integration

Skill para gerenciar containers NVIDIA NGC no ambiente Bruno (dual RTX 3090, CUDA 13.3).

## Login

```bash
# Já autenticado via docker login nvcr.io
# Se precisar renovar:
docker login nvcr.io --username '$oauthtoken'
# Password: nvapi-JyoP... (da chave NVIDIA_NGC_KEY no .env)
```

## Imagens Disponíveis

| Imagem | Uso | Comando |
|---|---|---|
| `nvcr.io/nvidia/vllm:26.03-py3` | vLLM oficial NVIDIA (CUDA 13.3) | `docker run --gpus all nvcr.io/nvidia/vllm:26.03-py3 vllm serve ...` |
| `nvcr.io/nvidia/pytorch:24.12-py3` | PyTorch otimizado NVIDIA | `docker run --gpus all -it nvcr.io/nvidia/pytorch:24.12-py3` |
| `nvcr.io/nvidia/cuda:13.3-devel` | CUDA toolkit | Para builds de código CUDA |

## Usando vLLM do NGC

Para substituir as imagens comunitárias do Docker Hub pelas oficiais NVIDIA:

```bash
# Embedding GPU:0 com imagem NVIDIA
docker run -d --name vllm-embedding-ngc --gpus '"device=0"' \
  -p 8002:8000 \
  -v /data/cache:/root/.cache/huggingface \
  --restart unless-stopped \
  nvcr.io/nvidia/vllm:26.03-py3 \
  vllm serve "Qwen/Qwen3-Embedding-8B" \
  --port 8000 --dtype auto --max-model-len 8192 \
  --gpu-memory-utilization 0.9
```

## Pitfalls

- **Imagens NGC são grandes** (>10GB cada) — baixar com paciência
- **CUDA 13.3** é suportado pelas imagens NGC mais recentes (diferente do vLLM comunitário)
- **NVIDIA_API_KEY** no .env ($NVIDIA_API_KEY) é para NVIDIA NIM API, não para NGC
- **Token NGC** ($NVIDIA_NGC_KEY) é separado da chave NIM — cada um tem seu propósito
- `docker login nvcr.io` expira tokens — renovar se `docker pull` falhar com auth
- Acesso ao NGC requer conta NVIDIA Developer (gratuita)
