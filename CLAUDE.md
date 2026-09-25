# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Redirects every request on the legacy domain `westphalia-kn.de` to `https://twv-westphalia.de`. The redirect is a 301 `/*` route in `src/staticwebapp.config.json`; `src/index.html` (German, `<meta http-equiv="Refresh">`) is only a fallback. There is no application build step; almost all activity in this repo is Terraform infrastructure and Renovate dependency bumps.

## Layout

- `src/` — static site content, uploaded as-is to Azure Static Web Apps (`app_location: /src`, app/API builds skipped).
- `infra/production/` — the only Terraform root module (one environment: production). Values live in `terraform.tfvars`; the `azurerm` backend is configured empty (`backend.tf`) and filled in by CI via `-backend-config`.
- `infra/.tflint.hcl` — TFLint config with the azurerm ruleset.

## Infrastructure architecture

`infra/production/main.tf` wires Azure and Cloudflare together:

- An Azure resource group + `azurerm_static_web_app` (Free SKU by default) hosts the page. Resource names follow `<type>-${app_name}-${env}-${resource_id}`.
- DNS lives in Cloudflare (zone looked up by name). Records are **not proxied** (`proxied = false`).
- Apex domain (`westphalia-kn.de`) uses `dns-txt-token` validation: Azure produces a token, Terraform writes it to a Cloudflare TXT record (`ignore_changes = [content]` so later token rotation doesn't churn), and a CNAME at the apex is flattened by Cloudflare.
- `www` subdomain uses `cname-delegation` validation, which depends on a `time_sleep` (120s) after the DNS records are created to allow propagation.
- The Static Web App's `api_key` is exposed as the sensitive output `deployment_token`, which the deploy workflow reads to upload `src/`.

Providers: `hashicorp/azurerm`, `cloudflare/cloudflare`, `hashicorp/time` (versions pinned with `~>` in `terraform.tf`; Renovate bumps them).

## Commands

Local validation (no backend needed). If `infra/production/.terraform/` holds stale backend config from an earlier init, delete it first:

```sh
cd infra/production
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
cd .. && tflint --init && tflint --recursive
```

`terraform plan`/`apply` against real state requires Azure auth (Azure AD / OIDC, `ARM_*` env vars), a `CLOUDFLARE_API_TOKEN`, and backend config (resource group, storage account, container, state key) — these come from GitHub environment variables and aren't in the repo, so plans are normally run through CI.

## CI/CD (`.github/workflows/`)

- **PRs to `main`** (`terraform-plan.yml`): validate + plan the production environment. Uses reusable actions from `ThorstenSauter/terraform-actions`.
- **Push to `main`** (`deploy-production.yml`): `terraform apply`, then a refresh-only apply so the `deployment_token` output reflects the current (possibly rotated) API key, then `Azure/static-web-apps-deploy` uploads `src/`. Runs are serialized by a non-cancelling `concurrency` group.

Merging to `main` applies infrastructure changes to production immediately. Actions are pinned by commit SHA with a version comment; keep that convention when editing workflows.
