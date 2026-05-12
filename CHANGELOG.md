# Changelog

All notable changes to `terraform-shared-config` are documented here.

This file is managed by [release-please](https://github.com/googleapis/release-please) — please don't edit it manually. Use [Conventional Commits](https://www.conventionalcommits.org) in PR titles to drive changelog generation.

The repo follows semantic versioning. Consumers pin to `@v1` (recommended) or to an exact `@v1.x.y`. The floating `v1` tag is repointed to the latest `v1.x.y` on every release.

## [1.0.5](https://github.com/devotica-labs/terraform-shared-config/compare/v1.0.4...v1.0.5) (2026-05-12)


### Bug Fixes

* **conftest:** bump from 0.46.0 → 0.56.0 to support 'import rego.v1' ([#23](https://github.com/devotica-labs/terraform-shared-config/issues/23)) ([3312b79](https://github.com/devotica-labs/terraform-shared-config/commit/3312b790cf7b5aa0b2a2c0c47a10565ee577784f))

## [1.0.4](https://github.com/devotica-labs/terraform-shared-config/compare/v1.0.3...v1.0.4) (2026-05-12)


### Bug Fixes

* **conftest:** plan from examples/basic instead of module root ([#21](https://github.com/devotica-labs/terraform-shared-config/issues/21)) ([49c8dab](https://github.com/devotica-labs/terraform-shared-config/commit/49c8dab0e776d0b28ef685c0f0d2f0871d1c9e76))

## [1.0.3](https://github.com/devotica-labs/terraform-shared-config/compare/v1.0.2...v1.0.3) (2026-05-12)


### Bug Fixes

* replace tfsec-action with trivy, conftest-action with binary ([#19](https://github.com/devotica-labs/terraform-shared-config/issues/19)) ([7a15017](https://github.com/devotica-labs/terraform-shared-config/commit/7a1501712154f4089cd49dcfe426fc450f8dff5e))

## [1.0.2](https://github.com/devotica-labs/terraform-shared-config/compare/v1.0.1...v1.0.2) (2026-05-08)

### Bug Fixes

* **workflows:** unblock org consumers — replace `gitleaks/gitleaks-action` (paid org-license requirement) with the upstream OSS binary download via new `gitleaks-version` input
* **workflows:** make `infracost` truly informational — skip cleanly when `INFRACOST_API_KEY` secret is unset, plus `continue-on-error` so a CLI hiccup cannot turn a green PR red
* **workflows:** add `terraform-docs-auto-update` input — when `true`, the `terraform-docs verify` job regenerates README and pushes `chore(docs): regenerate terraform-docs` to the PR branch instead of failing on diff

## [1.0.1](https://github.com/devotica-labs/terraform-shared-config/compare/v1.0.0...v1.0.1) (2026-05-07)

### Bug Fixes

* **workflows:** correct broken SHA pins for `bridgecrewio/checkov-action`, `gitleaks/gitleaks-action`, `infracost/actions/setup`

## [1.0.0](https://github.com/devotica-labs/terraform-shared-config/releases/tag/v1.0.0) (2026-05-04)

### Features

* Initial scaffold of the Devotica Terraform shared-config catalog
* Reusable `terraform-module-ci.yml` workflow — fmt, validate, tflint, tfsec, gitleaks, checkov, conftest, terraform test, terraform-docs verify, examples build, infracost
* Reusable `terraform-project-ci.yml` workflow — per-service plan/apply matrix with OIDC, drift gates, infracost
* Canonical tool configs: `pre-commit/.pre-commit-config.yaml`, `tflint/.tflint.hcl`, `terraform-docs/.terraform-docs.yml`, `checkov/.checkov.yaml`
