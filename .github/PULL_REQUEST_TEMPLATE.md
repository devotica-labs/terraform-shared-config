<!--
Thanks for the PR. Fill in the sections below — the reviewer reads this
*before* opening the diff. A clear PR description usually means a 5-minute
review instead of a 30-minute investigation.

Title format: Conventional Commits.
  feat(workflows): add OpenTofu compatibility job
  fix(tflint): correct AWS plugin version pin
  docs: clarify how project repos consume project-ci
  feat!: drop Terraform 1.5 support              # major bump
-->

## What & why

<!-- 1–3 sentences. What does this change do? What pain or gap motivated it? -->

## Behaviour change for consumers

<!-- Be honest. Say "none" if it's a no-op for downstream repos.
     If there's a behaviour change:
       - Is it backwards-compatible? (new optional input vs. changed default)
       - What does a consumer have to do, if anything, to adopt?
       - Should this trigger a major / minor / patch version bump?
-->

## Tested how

<!-- Choose all that apply, replace [x] for done:
- [ ] yamllint + actionlint pass locally (`pre-commit run -a` or `actionlint`)
- [ ] Validated against a real consumer repo on a feature branch (link the PR)
- [ ] Reviewed the diff against examples/*.example.yml — kept them in sync
- [ ] Updated CHANGELOG.md (or relying on release-please to do it)
-->

## Checklist

- [ ] Conventional Commit title (`feat:` / `fix:` / `docs:` / `chore:` / `feat!:`).
- [ ] No new required input — adding required inputs is a major version bump.
- [ ] Every new GitHub Action is SHA-pinned with a `# vX.Y.Z` comment.
- [ ] Every consumer-facing input that flows into a `run:` block is funnelled through `env:` (no direct `${{ inputs.x }}` interpolation in shell).
- [ ] If this is a breaking change, the PR title uses `feat!:` / `fix!:` and the body explains the migration step.

## Related

<!-- Issue, ADR, spec doc section reference, related PR. Optional. -->
