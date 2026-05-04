# Contributing

Thanks for your interest. **Issues** are welcome from anyone — please open one if you spot a bug, have a question, or want to suggest a feature.

**Pull requests** at this time are accepted only from members of the Devotica engineering team. This is a temporary policy while the catalog stabilises; we'll revisit as the project matures.

## For Devotica engineers

### Before you change anything

1. Fork the repo or create a branch.
2. Run `pre-commit install` so the local hooks fire on commit.
3. Read this file end to end.

### Workflow changes

- Pin every action by commit SHA, not by tag. Dependabot keeps SHAs fresh.
- Don't add an input without a default. Adding required inputs is a breaking change.
- Don't introduce a new external service (SaaS, registry, runner) without an ADR in [`terraform-adrs`](https://github.com/devotica-labs/terraform-adrs).

### Config changes

- Bumping a tool version: minor bump if backward-compatible, major if it changes default behaviour for consumers.
- Adding a new lint rule: start as informational. Flip to blocking after one full release cycle so consumers can fix existing violations on their schedule.

### Commit messages

We use Conventional Commits (`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`). The release-please workflow consumes these to compute the next version.

```
feat(module-ci): add OpenTofu compatibility job
fix(tflint): correct AWS plugin version pin
docs: clarify how project repos consume project-ci
feat!: drop Terraform 1.5 support  # major bump
```

### Releases

`release-please` opens a Release PR automatically when commits land on `main`. Approve and merge that PR to cut a tag. Consumers update their `@vX.Y.Z` pins on their next regular maintenance.

## Reporting security issues

Don't open a public issue. Email `security@devotica.com` with `[terraform-shared-config]` in the subject. We follow a 90-day responsible disclosure policy.

## Code of Conduct

By contributing you agree to abide by the Contributor Covenant Code of Conduct.
