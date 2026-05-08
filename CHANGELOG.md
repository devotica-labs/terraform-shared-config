# Changelog

All notable changes to `terraform-shared-config` are documented here.

This file is managed by [release-please](https://github.com/googleapis/release-please) — please don't edit it manually. Use [Conventional Commits](https://www.conventionalcommits.org) in PR titles to drive changelog generation.

The repo follows semantic versioning. Consumers pin to `@v1` (recommended) or to an exact `@v1.x.y`. The floating `v1` tag is repointed to the latest `v1.x.y` on every release.

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
