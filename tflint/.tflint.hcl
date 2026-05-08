# Devotica canonical tflint config.
#
# Enables the AWS plugin and turns on every documentation rule.
# Modules that don't pass these are not Devotica modules.

config {
  format     = "compact"
  call_module_type = "all"
}

plugin "terraform" {
  enabled = true
  preset  = "all"
}

plugin "aws" {
  enabled = true
  version = "0.32.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Mandatory documentation
rule "terraform_documented_variables" { enabled = true }
rule "terraform_documented_outputs"   { enabled = true }

# Naming — Foundation Plan §15.1 mandates lower_snake_case
rule "terraform_naming_convention" {
  enabled = true
  format  = "snake_case"
}

# Force pinning of providers — supply chain hygiene
rule "terraform_required_providers" { enabled = true }
rule "terraform_required_version"   { enabled = true }

# Mandatory tag set per Foundation Plan §15.2 — all six tags must be present
# on every taggable AWS resource. tflint catches this at PR time so the OPA
# conftest gate isn't the first place the gap surfaces.
rule "aws_resource_missing_tags" {
  enabled = true
  tags = [
    "Environment",
    "Project",
    "Owner",
    "CostCenter",
    "ManagedBy",
    "Repo",
  ]
}

# Standard hygiene
rule "terraform_unused_declarations"  { enabled = true }
rule "terraform_typed_variables"      { enabled = true }
rule "terraform_module_pinned_source" { enabled = true }
