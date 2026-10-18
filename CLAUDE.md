# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Redirects every request on the legacy domain `westphalia-kn.de` to `https://twv-westphalia.de`. The redirect is a 301 `/*` route in `src/staticwebapp.config.json`; `src/index.html` (German, `<meta http-equiv="Refresh">`) is only a fallback. There is no application build step; almost all activity in this repo is Terraform infrastructure and Renovate dependency bumps.

## Layout

- `src/` — static site content, uploaded as-is to Azure Static Web Apps (`app_location: /src`, app/API builds skipped).
- `infra/production/` — the only Terraform root module (one environment: production). Values live in `terraform.tfvars`; the `azurerm` backend is configured empty (`backend.tf`) and filled in by CI via `-backend-config`.
- `infra/.tflint.hcl` — TFLint config with the azurerm ruleset.

## Infrastructure architecture

`infra/production/main.tf` creates the resource group and calls the shared module [`ThorstenSauter/cloudflare-azure-static-web-app`](https://github.com/ThorstenSauter/cloudflare-azure-static-web-app) (pinned with `?ref=X.Y.Z`, bumped by Renovate). The module owns the Azure Static Web App (Free SKU by default, `repository_*` ignored because CI deploys the content), the Cloudflare DNS records (DNS-only, zone looked up by `cloudflare_zone_name`) and both custom domains: the apex with `dns-txt-token` validation and a CNAME Cloudflare flattens, and `www` with `cname-delegation` after a 120s propagation wait. Change domain or DNS behaviour in the module, not here. Resource names follow `<type>-${app_name}-${env}-${resource_id}`.

Don't rename the module call (`module.static_web_app`): Terraform would recreate the Static Web App and its custom domains. A rename needs a `moved` block.

The `deployment_token` output is the Static Web App's API key. CI reads it with `terraform output -raw deployment_token` to deploy the site, so don't remove or rename it.

Provider versions (`azurerm`, `cloudflare`, `time`) are pinned in `terraform.tf` and bumped by Renovate; the module only sets lower bounds.

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
