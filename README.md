# terraform-shared-config

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](LICENSE)
[![meta-ci](https://github.com/devotica-labs/terraform-shared-config/actions/workflows/meta-ci.yml/badge.svg)](https://github.com/devotica-labs/terraform-shared-config/actions/workflows/meta-ci.yml)
[![Release](https://github.com/devotica-labs/terraform-shared-config/actions/workflows/release.yml/badge.svg)](https://github.com/devotica-labs/terraform-shared-config/actions/workflows/release.yml)

Canonical reusable GitHub Actions workflows and Terraform tooling configs for the Devotica Terraform practice. Consumed by every repo under [`devotica-labs`](https://github.com/devotica-labs).

> **Why this repo exists.** One source of truth for the entire CI / release / drift pipeline. Bumping a tool version, tightening a gate, or adding a new check is a single PR here that propagates to every consumer on their next `@vX.Y.Z` bump (or automatically, if pinned at floating `@v1`).

---

## Quick reference — when each workflow runs

This repo ships **six** workflow files. They split into two groups by what triggers them:

| Workflow | `on:` trigger | Runs in **this** repo? | Runs in **consumer** repos? |
|---|---|:---:|:---:|
| [`meta-ci.yml`](#meta-ciyml) | `pull_request` + `push` to `main` | ✅ every PR / push | ❌ |
| [`release.yml`](#releaseyml) | `push` to `main` | ✅ release-please on `main` | ❌ |
| [`terraform-module-ci.yml`](#terraform-module-ciyml) | `workflow_call` only | ❌ | ✅ via wrapper |
| [`terraform-project-ci.yml`](#terraform-project-ciyml) | `workflow_call` only | ❌ | ✅ via wrapper |
| [`terraform-module-release.yml`](#terraform-module-releaseyml) | `workflow_call` only | ❌ | ✅ via wrapper |
| [`terraform-drift.yml`](#terraform-driftyml) | `workflow_call` only | ❌ | ✅ via wrapper (cron) |

Reusable workflows do **not** fire when this repo is pushed. They only fire when a consumer repo invokes them via `uses: devotica-labs/terraform-shared-config/.github/workflows/<file>@v1`.

---

## Architecture

```mermaid
flowchart LR
    subgraph Consumers["Consumer repos under devotica-labs"]
        MOD["terraform-aws-vpc<br/>terraform-aws-iam-role<br/>terraform-aws-rds<br/>...10 modules"]
        PROJ["sample-infra<br/>client-A-infra<br/>client-B-infra"]
    end

    subgraph Shared["terraform-shared-config (this repo)"]
        MCI["terraform-module-ci.yml<br/>module CI"]
        PCI["terraform-project-ci.yml<br/>project CI"]
        MRL["terraform-module-release.yml<br/>module release"]
        DRF["terraform-drift.yml<br/>drift detection"]
        META["meta-ci.yml<br/>self-linting (PR gate)"]
        SELFREL["release.yml<br/>self-versioning (release-please)"]
        CFG["pre-commit · tflint · terraform-docs<br/>checkov · editorconfig"]
    end

    subgraph Policies["devotica-labs/terraform-policies"]
        OPA["OPA / conftest rule pack"]
    end

    subgraph Ext["External targets"]
        REG["registry.terraform.io<br/>devotica-labs namespace"]
        SBX["AWS Sandbox account<br/>+ client AWS accounts"]
    end

    MOD -->|workflow_call @v1| MCI
    MOD -->|workflow_call @v1| MRL
    PROJ -->|workflow_call @v1| PCI
    PROJ -->|cron + workflow_call @v1| DRF
    MOD -.->|references| CFG
    PROJ -.->|references| CFG

    MCI -->|conftest fetches| OPA
    PCI -->|conftest fetches| OPA

    MRL -->|publishes signed tags| REG
    PCI -->|OIDC plan/apply| SBX
    DRF -->|OIDC read-only plan| SBX

    classDef shared fill:#1F4E79,color:#fff,stroke:#1F4E79;
    classDef consumer fill:#eaf1f8,color:#1a1a1a,stroke:#2E75B6;
    classDef pol fill:#dcfce7,color:#1a1a1a,stroke:#15803d;
    classDef ext fill:#fef3c7,color:#1a1a1a,stroke:#854d0e;
    class MCI,PCI,MRL,DRF,META,SELFREL,CFG shared;
    class MOD,PROJ consumer;
    class OPA pol;
    class REG,SBX ext;
```

---

## Quickstart — adopting in a new repo

Five steps to wire up a fresh `devotica-labs/terraform-aws-<name>` module repo (or `<client>-infra` project repo):

1. **CI workflow.** Copy [`examples/module-ci.example.yml`](./examples/module-ci.example.yml) into the new repo as `.github/workflows/ci.yml` (or [`examples/project-ci.example.yml`](./examples/project-ci.example.yml) → split into `terraform-plan.yml` + `terraform-apply.yml` for project repos — see file header for the split logic).
2. **Release workflow** (module repos only). Add a 10-line wrapper at `.github/workflows/release.yml` that calls `terraform-module-release.yml@v1` — see [§terraform-module-release.yml](#terraform-module-releaseyml).
3. **Drift workflow** (project repos only). Add a wrapper at `.github/workflows/drift.yml` that calls `terraform-drift.yml@v1` on a daily `schedule: cron` — see [§terraform-drift.yml](#terraform-driftyml).
4. **Tool configs.** Copy the four canonical configs (`tflint/.tflint.hcl`, `pre-commit/.pre-commit-config.yaml`, `terraform-docs/.terraform-docs.yml`, `checkov/.checkov.yaml`) plus `.editorconfig` into the repo root.
5. **Optional secrets.** Add `INFRACOST_API_KEY` as an org-level secret if you want PR cost-diff comments. The job skips silently when the secret is unset, so this isn't blocking.

Pin to `@v1` (recommended — auto-tracks the latest minor) or `@v1.x.y` (exact pin, used only when chasing a regression). See [Versioning policy](#versioning-policy).

---

## Workflows

### `meta-ci.yml`

**Type:** Self-CI. **Trigger:** `pull_request` + `push` to `main`. **Visibility:** runs only in this repo.

This repo's reusable workflows are consumed by every other repo in the org — a typo here breaks them all. `meta-ci` is the safety net that catches issues before they ever reach the floating `@v1` tag.

| Job | What it checks |
|---|---|
| `actionlint` | `actionlint` v1.7.7 over every workflow YAML — unknown contexts, malformed `if:`, bad `uses:` SHAs |
| `yamllint` | `yamllint` v1.35.1 strict mode (line-length and document-start relaxed for GHA conventions) |
| `release-please-schema` | JSON-schema validates `.github/release-please-config.json` against the upstream release-please schema; verifies `…manifest.json` is a `{path: semver}` map |
| `json-syntax` | Every `.json` file under version control parses cleanly — catches stray trailing commas in any committed config |

If any job fails, the PR is blocked. Branch protection on `main` should require `meta-ci` as a status check.

---

### `release.yml`

**Type:** Self-CI. **Trigger:** `push` to `main`. **Visibility:** runs only in this repo.

Versions this repo. On every push to `main`, [release-please](https://github.com/googleapis/release-please) opens or updates a release PR with the next version bump and a generated changelog.

| Job | Behaviour |
|---|---|
| `release-please` | Opens a release PR (e.g. `chore(main): release 1.2.0`). On merge of that PR, creates the `v1.2.0` GitHub Release and pushes the immutable tag |
| `retag-floating-major` | Runs only when `release_created == true`. Force-moves the floating `v<MAJOR>` tag (e.g. `v1`) to the newly published release so every consumer pinned at `@v1` picks up the change automatically |

> You never `git tag` this repo by hand. Conventional Commits (`feat:`, `fix:`, `feat!:`) drive the bump.

---

### `terraform-module-ci.yml`

**Type:** Reusable. **Trigger:** `workflow_call`. **Consumed by:** every `devotica-labs/terraform-aws-*` module repo.

The full module-CI gauntlet — fmt, validate, lint, sec, policy, test, docs, examples, cost.

#### Inputs

| Input | Type | Default | Purpose |
|---|---|---|---|
| `terraform-version` | string | `1.9.5` | Pin for `hashicorp/setup-terraform` |
| `working-directory` | string | `.` | Module root (use when the repo nests modules) |
| `run-terraform-test` | bool | `true` | Runs `terraform test -filter=…` for every file listed in `terraform-test-files` (default unit + contract) |
| `terraform-test-files` | string (JSON array) | `'["tests/unit.tftest.hcl","tests/contract.tftest.hcl"]'` | Override when test files are named differently or split into more layers |
| `run-tflint` | bool | `true` | tflint with AWS plugin, recursive |
| `run-tfsec` | bool | `true` | `aquasecurity/tfsec-action` — fails on HIGH/CRITICAL findings |
| `run-checkov` | bool | `true` | Checkov terraform framework |
| `run-conftest` | bool | `true` | Pulls `terraform-policies@<conftest-policy-ref>` and runs conftest against `terraform plan -json` |
| `run-terraform-docs-check` | bool | `true` | terraform-docs README sync (mode controlled by `terraform-docs-auto-update`) |
| `terraform-docs-auto-update` | bool | `false` | `true` → bot inject + git-push README; `false` → CI fails on diff |
| `run-infracost` | bool | `true` | PR cost-diff comment (Tier-2 informational; skips silently when `INFRACOST_API_KEY` unset) |
| `run-examples-build` | bool | `true` | `terraform validate` in every `examples/<name>/` folder listed in `examples-build-targets` (default `basic` + `complete`) |
| `examples-build-targets` | string (JSON array) | `'["basic","complete"]'` | Override when a module ships extra example folders (e.g. `with-ipv6`, `multi-region`) |
| `checkov-blocking` | bool | `false` | Flip Checkov to blocking once skip list is reviewed |
| `conftest-policy-ref` | string | `v1` | Git ref of `terraform-policies` to use |
| `gitleaks-version` | string | `8.18.4` | OSS gitleaks binary version (no paid license) |

#### Secrets

| Secret | Required | Purpose |
|---|---|---|
| `INFRACOST_API_KEY` | optional | When unset, infracost job skips silently |

#### Pipeline shape

```mermaid
flowchart LR
    PR["PR opened"] --> FMT["fmt"]
    FMT --> VAL["validate"]
    VAL --> P2A["tflint"]
    VAL --> P2B["tfsec<br/>HIGH/CRIT"]
    VAL --> P2C["gitleaks (binary)"]
    VAL --> P2D["terraform-docs"]
    VAL --> P3A["conftest (central pack)"]
    VAL --> P3B["terraform test"]
    VAL --> P4A["checkov<br/>(informational)"]
    VAL --> P4B["infracost<br/>(informational)"]
    VAL --> P4C["examples build"]
    P2A --> GATE{all green?}
    P2B --> GATE
    P2C --> GATE
    P2D --> GATE
    P3A --> GATE
    P3B --> GATE
    P4C --> GATE
    P4A -.->|comment| PR
    P4B -.->|comment| PR
    GATE -- yes --> REVIEW["non-author review"]
    REVIEW --> MERGE["merge to main"]
    classDef inform fill:#fef3c7,stroke:#854d0e,color:#854d0e;
    class P4A,P4B inform;
```

#### Consumer wrapper

`github.com/devotica-labs/terraform-aws-<name>/.github/workflows/ci.yml`:

```yaml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

permissions:
  contents: write          # required if terraform-docs-auto-update = true
  pull-requests: write
  id-token: write

jobs:
  ci:
    uses: devotica-labs/terraform-shared-config/.github/workflows/terraform-module-ci.yml@v1
    with:
      terraform-version: "1.9.5"
      working-directory: "."
      terraform-docs-auto-update: true
    secrets: inherit
```

> 💡 A copy-pasteable version with every override commented out is at [`examples/module-ci.example.yml`](./examples/module-ci.example.yml).

---

### `terraform-project-ci.yml`

**Type:** Reusable. **Trigger:** `workflow_call`. **Consumed by:** `sample-infra` and every `<client>-infra` project monorepo.

Per-service plan / apply pipeline for service-first project layouts (`vpc/`, `s3/`, `rds/`, …) per Foundation Plan §4.

#### Inputs

| Input | Type | Required | Default | Purpose |
|---|---|---|---|---|
| `services` | string (JSON array) | ✓ | — | e.g. `'["vpc","s3","rds"]'` — drives the per-service matrix |
| `environment` | string | ✓ | — | `sandbox` / `dev` / `stg` / `prod` — selects `tfvars/<env>.tfvars` and `backend/config.<env>.hcl` |
| `aws-role-arn` | string | ✓ | — | OIDC IAM role to assume in the target account |
| `aws-region` | string | — | `ap-south-1` | |
| `terraform-version` | string | — | `1.9.5` | |
| `run-plan` | bool | — | `true` | Run plan + conftest + infracost. Set false on apply jobs |
| `run-apply` | bool | — | `false` | Run `terraform apply -auto-approve`. Set true on apply jobs gated by GitHub Environment |
| `run-tflint` / `run-tfsec` / `run-checkov` / `run-conftest` / `run-infracost` | bool | — | `true` | Per-job toggles |
| `conftest-policy-ref` | string | — | `v1` | Git ref of `terraform-policies` |
| `gitleaks-version` | string | — | `8.18.4` | |

#### Secrets

| Secret | Required | Purpose |
|---|---|---|
| `INFRACOST_API_KEY` | optional | PR cost-diff comments — skips silently when unset |

#### Pipeline shape

```mermaid
flowchart LR
    PR["PR / push"] --> FMT["fmt"]
    FMT --> GL["gitleaks (binary)"]
    GL --> MX{per-service matrix}
    MX --> TFL["tflint"]
    MX --> TFS["tfsec<br/>HIGH/CRIT"]
    MX --> CKV["checkov<br/>(informational)"]
    MX --> OIDC["AWS OIDC"]
    OIDC --> INIT["terraform init"]
    INIT --> PLAN["plan + conftest"]
    PLAN --> COST["infracost<br/>(informational)"]
    PLAN -- run-apply=true --> APPLY["terraform apply"]
    classDef inform fill:#fef3c7,stroke:#854d0e,color:#854d0e;
    class CKV,COST inform;
```

#### Consumer wrappers

PR-time plan workflow:

```yaml
# sample-infra/.github/workflows/terraform-plan.yml
on:
  pull_request:
    branches: [main]

permissions:
  id-token: write
  contents: read
  pull-requests: write

jobs:
  plan:
    uses: devotica-labs/terraform-shared-config/.github/workflows/terraform-project-ci.yml@v1
    with:
      services: '["vpc"]'
      environment: "sandbox"
      aws-role-arn: ${{ vars.AWS_OIDC_ROLE_ARN }}
      run-plan: true
      run-apply: false
    secrets: inherit
```

Merge-time apply workflow:

```yaml
# sample-infra/.github/workflows/terraform-apply.yml
on:
  push:
    branches: [main]

jobs:
  apply_sandbox:
    uses: devotica-labs/terraform-shared-config/.github/workflows/terraform-project-ci.yml@v1
    with:
      services: '["vpc"]'
      environment: "sandbox"
      aws-role-arn: ${{ vars.AWS_OIDC_ROLE_ARN }}
      run-plan: false
      run-apply: true
    secrets: inherit
  # apply_prod (gated by GitHub Environment "production") — see comment in
  # the file for the enable-procedure.
```

> 💡 Copy-pasteable plan + apply pair (with the `apply_prod` block ready to uncomment) at [`examples/project-ci.example.yml`](./examples/project-ci.example.yml).

---

### `terraform-module-release.yml`

**Type:** Reusable. **Trigger:** `workflow_call`. **Consumed by:** every `devotica-labs/terraform-aws-*` module repo via a thin `release.yml` wrapper triggered on push to `main`.

Replaces the duplicated release pipeline that used to live inline in every module repo.

#### Pipeline

```
push to main
   ↓
release-please opens / updates release PR (Conventional Commits → version + CHANGELOG)
   ↓ (PR merged)
GitHub Release created · vX.Y.Z tag pushed
   ↓
cosign keyless-sign tag (Sigstore Fulcio + Rekor transparency log)
   ↓
CycloneDX SBOM generated for the module
   ↓
Both artifacts attached to the GitHub Release
   ↓
Floating v<MAJOR> tag force-moved to the new release
```

#### Inputs

| Input | Default | Purpose |
|---|---|---|
| `release-type` | `terraform-module` | release-please release-type |
| `release-please-config-file` | `.github/release-please-config.json` | release-please config |
| `release-please-manifest-file` | `.github/release-please-manifest.json` | release-please manifest |
| `cosign-installer-version` | `v3` | `sigstore/cosign-installer` (informational; SHA-pinned in workflow) |
| `retag-floating-major` | `true` | Force-move `v<MAJOR>` after publish |

#### Permissions required at the wrapper

```yaml
permissions:
  contents: write       # create releases, tag, force-move floating tag
  pull-requests: write  # release-please opens release PRs
  id-token: write       # cosign keyless OIDC signing (Fulcio)
```

#### Consumer wrapper

```yaml
# terraform-aws-vpc/.github/workflows/release.yml
name: release

on:
  push:
    branches: [main]

permissions:
  contents: write
  pull-requests: write
  id-token: write

jobs:
  release:
    uses: devotica-labs/terraform-shared-config/.github/workflows/terraform-module-release.yml@v1
    secrets: inherit
```

---

### `terraform-drift.yml`

**Type:** Reusable. **Trigger:** `workflow_call`. **Consumed by:** `sample-infra` and every `<client>-infra` repo via a thin wrapper triggered on `schedule: cron`.

Daily drift detection — runs `terraform plan -detailed-exitcode` per service per environment. Exit code `2` (drift detected) opens a GitHub issue and fails the workflow run so it surfaces on the repo dashboard.

#### Inputs

| Input | Type | Required | Default | Purpose |
|---|---|---|---|---|
| `services` | string (JSON array) | ✓ | — | e.g. `'["vpc","s3","rds"]'` |
| `environment` | string | ✓ | — | Target env — must match an existing `tfvars/<env>.tfvars` |
| `aws-role-arn` | string | ✓ | — | OIDC IAM role |
| `aws-region` | string | — | `ap-south-1` | |
| `terraform-version` | string | — | `1.9.5` | Must match the apply path |
| `open-issue-on-drift` | bool | — | `true` | Open a GitHub issue on exit code 2 |
| `fail-on-drift` | bool | — | `true` | Fail the run on drift (visible on dashboard) |

#### Permissions required at the wrapper

```yaml
permissions:
  id-token: write   # OIDC into target AWS account
  contents: read
  issues: write     # open drift issue
```

#### Consumer wrapper

```yaml
# sample-infra/.github/workflows/drift.yml
name: drift

on:
  schedule:
    - cron: "0 4 * * *"   # 04:00 UTC daily
  workflow_dispatch:        # manual ad-hoc trigger

permissions:
  id-token: write
  contents: read
  issues: write

jobs:
  drift_sandbox:
    uses: devotica-labs/terraform-shared-config/.github/workflows/terraform-drift.yml@v1
    with:
      services: '["vpc"]'
      environment: "sandbox"
      aws-role-arn: ${{ vars.AWS_OIDC_ROLE_ARN }}
    secrets: inherit
```

---

## Tool configs

Workflow files are only half the story. The other half is the canonical tool configuration that every repo should drop into its root.

| Path | Drop into consumer repo as | Purpose |
|---|---|---|
| [`pre-commit/.pre-commit-config.yaml`](./pre-commit/.pre-commit-config.yaml) | `.pre-commit-config.yaml` | Local pre-commit hooks — fmt, validate, tflint, gitleaks |
| [`tflint/.tflint.hcl`](./tflint/.tflint.hcl) | `.tflint.hcl` | tflint AWS plugin + tagging enforcement |
| [`terraform-docs/.terraform-docs.yml`](./terraform-docs/.terraform-docs.yml) | `.terraform-docs.yml` | terraform-docs config — generates README inputs/outputs |
| [`checkov/.checkov.yaml`](./checkov/.checkov.yaml) | `.checkov.yaml` | Checkov skip list (informational mode by default) |
| [`.editorconfig`](./.editorconfig) | `.editorconfig` | Whitespace / line-ending baseline |

> Treat this repo as the source of truth. When you need to tighten a rule, update the file here first, then bump consumers' `@v1` reference (or rely on the floating `v1` tag picking up automatically). Drift between consumer-side copies and this canonical version is caught at PR time by the `fmt`, `tflint`, and `terraform-docs` jobs.

---

## Versioning policy

This repo follows [SemVer](https://semver.org) via Git tags. Consumers pin to a major version:

| Pin form | Behaviour |
|---|---|
| `@v1` (recommended) | Auto-tracks the latest `v1.x.y`. The `release.yml` workflow force-moves this floating tag on every release |
| `@v1.2.0` (exact) | Use only when chasing a regression — pin, fix, then return to `@v1` |
| `@main` | **Not supported.** Don't pin to floating refs |

What triggers each kind of bump:

| Bump | Triggered by |
|---|---|
| **Major** (`v1.x.y` → `v2.0.0`) | Removing a workflow input · changing default behaviour in a way consumers can break on · raising the minimum Terraform version |
| **Minor** (`v1.1.0` → `v1.2.0`) | Adding a new optional input · adding a new job · adding a new reusable workflow file |
| **Patch** (`v1.1.0` → `v1.1.1`) | Bumping a SHA-pinned action · tightening a non-default rule · doc-only changes |

Conventional Commits drive this. `feat:` → minor, `fix:` → patch, `feat!:` (or footer `BREAKING CHANGE:`) → major.

---

## Releases

| Tag | Date | Highlights |
|---|---|---|
| **`v1.1.0`** *(merged, awaiting release-please tag)* | 2026-05-08 | New reusable workflows: [`terraform-drift.yml`](./.github/workflows/terraform-drift.yml) and [`terraform-module-release.yml`](./.github/workflows/terraform-module-release.yml) (cosign + CycloneDX SBOM + auto-retag). Self-CI [`meta-ci.yml`](./.github/workflows/meta-ci.yml). New inputs `examples-build-targets` and `terraform-test-files` make the module-CI matrices configurable. Plus PR template and governance metadata. Backwards-compatible — every change adds optional surface |
| `v1.0.2` | 2026-05-08 | Unblock org consumers — gitleaks switched to OSS binary (no paid license) · `infracost` truly informational (skips silently when `INFRACOST_API_KEY` unset) · new `terraform-docs-auto-update` mode pushes regenerated README to PR branch |
| `v1.0.1` | 2026-05-07 | Corrected broken SHA pins for checkov, gitleaks, infracost actions |
| `v1.0.0` | 2026-05-04 | Initial scaffold — `terraform-module-ci.yml` + `terraform-project-ci.yml`, canonical `tflint`/`checkov`/`pre-commit`/`terraform-docs` configs |

See [CHANGELOG.md](./CHANGELOG.md) for the full release-please-generated history.

---

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md). External pull requests are not accepted at this time; please file issues for bug reports and feature requests.

---

## Governance

| File | Purpose |
|---|---|
| [`LICENSE`](./LICENSE) | Apache-2.0 |
| [`SECURITY.md`](./SECURITY.md) | Vulnerability reporting (`security@devotica.com`) + supported-versions policy |
| [`CODE_OF_CONDUCT.md`](./CODE_OF_CONDUCT.md) | Contributor Covenant 2.1 — `conduct@devotica.com` for reports |
| [`CONTRIBUTING.md`](./CONTRIBUTING.md) | Workflow rules, Conventional Commit conventions, release process |
| [`CHANGELOG.md`](./CHANGELOG.md) | release-please-managed history (don't edit by hand) |
| [`.github/CODEOWNERS`](./.github/CODEOWNERS) | Default reviews → `@cloud-leads`; workflows → `@cloud-leads + @security` |
| [`.github/dependabot.yml`](./.github/dependabot.yml) | Weekly GitHub Actions SHA refresh, Mon 09:00 IST |
| [`.github/PULL_REQUEST_TEMPLATE.md`](./.github/PULL_REQUEST_TEMPLATE.md) | What & why · behaviour change · tested how · checklist |

---

## License

Apache-2.0. See [LICENSE](./LICENSE).
