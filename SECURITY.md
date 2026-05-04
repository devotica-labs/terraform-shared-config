# Security policy

## Reporting a vulnerability

**Please do not open public GitHub issues for security vulnerabilities.**

Email `security@devotica.com` with `[terraform-shared-config]` in the subject line. Include:

- A description of the issue
- Steps to reproduce
- Affected versions / commit SHAs
- Your assessment of impact

You will receive an acknowledgement within 2 business days. We follow a 90-day responsible disclosure policy: we commit to fix or publicly acknowledge the issue within 90 days, and we'll credit you in the release notes (or anonymously, if you prefer).

## Supported versions

The latest minor version of each major series receives security updates:

| Version | Supported |
|---|---|
| `v1.x.y` (current) | Yes |
| Older majors | No (best-effort only) |

## Scope

This policy covers the workflow definitions, configuration files, and example consumer snippets in this repository. It does NOT cover:

- Vulnerabilities in upstream tools (Terraform, tflint, tfsec, etc.) — please report those upstream
- Vulnerabilities in consumer repos that use this config — those go to the consumer's `SECURITY.md`
