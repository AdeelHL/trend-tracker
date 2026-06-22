# Trend Tracker

A serverless REST API on AWS that periodically ingests data from a public API,
stores it as a time series, and exposes endpoints to query the history.

## Architecture

```
EventBridge (cron) ──▶ ingest Lambda ──▶ public API (fetch)
                                     ──▶ DynamoDB (write)

Client ──▶ API Gateway ──▶ api Lambda ──▶ DynamoDB (read)

GitHub push ─▶ GitHub Actions ─(OIDC, keyless)─▶ terraform apply ─▶ AWS
```

## Tech Stack

- **Python 3.13** — Lambda functions
- **AWS Lambda** — serverless compute
- **API Gateway** — public HTTPS API
- **DynamoDB** — serverless NoSQL storage (time series)
- **EventBridge** — scheduled ingestion
- **IAM** — permissions
- **Terraform** — infrastructure as code
- **GitHub Actions + OIDC** — CI/CD

## Status

🚧 Built in stages — see the build log below.

- [x] Stage 0 — Foundations & repo setup
- [x] Stage 1 — First Lambda by hand
- [ ] Stage 2 — Infrastructure with Terraform
- [ ] Stage 3 — DynamoDB + ingest Lambda
- [ ] Stage 4 — API Gateway + api Lambda
- [ ] Stage 5 — EventBridge schedule
- [ ] Stage 6 — Tests
- [ ] Stage 7 — CI/CD (GitHub Actions + OIDC)
- [ ] Stage 8 — Polish
