# Cron Jobs — Hermes Agent Bruno's Setup
# 3 jobs ativos, todos no_agent (scripts estáticos)

# ┌───────────── Job                     ┌────────── Schedule
# ├────────────── Nome                   ├─────────── Script
# ▼                                      ▼
gpu-temp-monitor       once in 30m       → cron/scripts/gpu-temp-monitor.sh
container-health-check 0 8 * * *         → cron/scripts/container-health-check.sh
disk-monitor           0 9 * * *         → cron/scripts/disk-monitor.sh

# Todos silenciosos — só notificam quando algo errado.
