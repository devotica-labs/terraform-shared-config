# Consumer examples

Copy-paste-ready snippets for repos that consume `terraform-shared-config`. Each example is documented inline with what runs, sane defaults, and the optional overrides you might want.

| File | For | Drop into |
|---|---|---|
| [`module-ci.example.yml`](./module-ci.example.yml) | Module repos (`terraform-aws-*`) | `.github/workflows/ci.yml` |
| [`project-ci.example.yml`](./project-ci.example.yml) | Project monorepos (`<client>-infra`, `sample-infra`) | `.github/workflows/terraform-plan.yml` + `terraform-apply.yml` (split — see file header) |

## Pinning policy

- **`@v1`** (recommended) — auto-tracks the latest `v1.x.y`. Bug fixes and additive features land automatically on the next CI run.
- **`@v1.2.0`** — exact pin. Use when chasing a regression or when an audit window forbids drift.
- **`@main`** — **not supported.** The reusable workflow contract is defined by tagged releases only.

## What's NOT in here

- AWS credential setup — handled per-account via OIDC (see `terraform-bootstrap-template`).
- Secret onboarding — `INFRACOST_API_KEY` (optional, Tier-2 informational), team-level secrets for any custom step you add downstream of the reusable call.
- Branch protection rules — configured in repo Settings, not in this YAML. Required-status-check names match the job names in the central workflows (`fmt`, `validate`, `tflint`, `tfsec`, `gitleaks`, `checkov`, `conftest (OPA policies)`, `terraform test (unit + contract)`, `terraform-docs verify`, `examples build`).
