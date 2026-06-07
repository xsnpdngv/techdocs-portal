# Runbook

## On-call basics

| Severity | Response time | Escalation                |
| -------- | ------------- | ------------------------- |
| SEV-1    | 15 minutes    | Page secondary on-call    |
| SEV-2    | 1 hour        | Notify team channel       |
| SEV-3    | Next business day | Open ticket           |

## Restart the service

```bash
kubectl -n prod rollout restart deployment/my-service
kubectl -n prod rollout status   deployment/my-service
```

## Common alerts

??? warning "HighErrorRate"
    1. Check the [overview dashboard](https://grafana.example.com/d/my-service).
    2. Inspect recent deployments: `kubectl -n prod rollout history deployment/my-service`.
    3. If a bad release is suspected: `kubectl -n prod rollout undo deployment/my-service`.

??? warning "QueueBacklog"
    Scale up the worker:
    ```bash
    kubectl -n prod scale deployment/worker --replicas=6
    ```
