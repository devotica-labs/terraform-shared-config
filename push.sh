#!/usr/bin/env bash
# One-shot script to push this scaffold to github.com/devotica-labs/terraform-shared-config.
#
# Prerequisites:
#   - gh CLI installed and authenticated as a devotica-labs Owner (`gh auth status` returns ok)
#   - You are inside the terraform-shared-config/ directory when you run this
#
# What it does:
#   1. Confirms you're in the right directory
#   2. Initializes git if not already
#   3. Creates the GitHub repo (public) under devotica-labs if it doesn't exist
#   4. Pushes main branch
#   5. Tags v1.0.0 so consumers can pin to @v1
#   6. Sets branch protection on main
#
# This is idempotent — safe to re-run if any step fails.

set -euo pipefail

REPO_NAME="terraform-shared-config"
ORG="devotica-labs"
DEFAULT_BRANCH="main"
INITIAL_TAG="v1.0.0"

cd "$(dirname "$0")"

# 1. Sanity check — we should be in terraform-shared-config/
if [[ "$(basename "$PWD")" != "$REPO_NAME" ]]; then
  echo "ERROR: must run this script from inside the $REPO_NAME directory."
  echo "current pwd: $PWD"
  exit 1
fi

# 2. Confirm gh CLI is authed and as the right user
if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh CLI not authenticated. Run 'gh auth login' first."
  exit 1
fi

WHOAMI=$(gh api user --jq .login)
echo "✓ gh CLI authenticated as: $WHOAMI"
echo

# 3. Confirm membership of devotica-labs
if ! gh api orgs/$ORG/members/$WHOAMI --silent 2>/dev/null; then
  echo "WARNING: $WHOAMI is not visible as a member of $ORG (may still be owner — proceeding)."
fi

# 4. Initialize git if needed
if [[ ! -d .git ]]; then
  echo "→ Initializing git repository"
  git init -b "$DEFAULT_BRANCH"
  git add .
  git commit -m "feat: initial scaffold

Reusable GitHub Actions workflows and canonical Terraform tooling configs
for the Devotica Terraform practice.

* terraform-module-ci.yml — reusable workflow for module repos
* terraform-project-ci.yml — reusable workflow for project monorepos
* canonical .pre-commit, .tflint.hcl, .terraform-docs.yml, .checkov.yaml

Refs: terraform-module-repo-plan-vpc-v1.3, governance-tooling-v1.0"
fi

# 5. Create the repo on GitHub if it doesn't exist
if ! gh repo view "$ORG/$REPO_NAME" >/dev/null 2>&1; then
  echo "→ Creating github.com/$ORG/$REPO_NAME (public)"
  gh repo create "$ORG/$REPO_NAME" \
    --public \
    --description "Reusable GHA workflows + canonical Terraform tooling configs for Devotica" \
    --source . \
    --remote origin \
    --push
else
  echo "✓ github.com/$ORG/$REPO_NAME already exists"
  if ! git remote get-url origin >/dev/null 2>&1; then
    git remote add origin "git@github.com:$ORG/$REPO_NAME.git"
  fi
  git push -u origin "$DEFAULT_BRANCH"
fi

# 6. Tag v1.0.0 so consumer repos can pin to @v1 immediately
if ! git rev-parse "$INITIAL_TAG" >/dev/null 2>&1; then
  echo "→ Tagging $INITIAL_TAG"
  git tag -a "$INITIAL_TAG" -m "Initial release of terraform-shared-config

Reusable workflows and canonical configs for the Devotica Terraform catalog."
  git push origin "$INITIAL_TAG"
fi

# 7. Branch protection on main
echo "→ Configuring branch protection on $DEFAULT_BRANCH"
gh api -X PUT "repos/$ORG/$REPO_NAME/branches/$DEFAULT_BRANCH/protection" \
  --input - >/dev/null <<'JSON'
{
  "required_status_checks": null,
  "enforce_admins": false,
  "required_pull_request_reviews": {
    "required_approving_review_count": 1,
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true
  },
  "restrictions": null,
  "required_linear_history": true,
  "allow_force_pushes": false,
  "allow_deletions": false,
  "required_conversation_resolution": true
}
JSON

echo
echo "All done."
echo
echo "Next steps:"
echo "  1. Browse https://github.com/$ORG/$REPO_NAME — confirm the README renders correctly"
echo "  2. From terraform-aws-vpc, point ci.yml at devotica-labs/terraform-shared-config@v1"
echo "  3. Cut v1.0.1 onwards via release-please (configure in a follow-up PR)"
