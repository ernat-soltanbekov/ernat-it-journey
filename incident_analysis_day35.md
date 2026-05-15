# Incident Analysis — Week 8 Day 7

## Scenario

Team successfully deployed API into Kubernetes.

After several weeks, operational problems appeared:
- PostgreSQL password was hardcoded inside GitHub repository
- developers rebuilt Docker image after every .env change
- staging environment accidentally connected to production database
- some Pods continued using outdated credentials after token rotation
- junior developer received unintended access to production API keys
- configurations between environments became inconsistent

CTO concluded that the team does not understand separation between code, configuration, and secrets.

---

## What Problem Is Happening

The core architectural problem is configuration hardcoding.

Application code and runtime configuration became tightly coupled.

This violates:
- Twelve-Factor App principles
- immutable infrastructure philosophy
- production deployment best practices

A production-ready Docker image must remain immutable.

Correct workflow:
1. image is built once
2. same image passes through environments
3. runtime configuration changes externally

If image rebuild is required for changing:
- database host
- API endpoint
- credentials
- feature flags

then deployment architecture is fundamentally broken.

---

## Why Secrets Inside Git Or Docker Images Are Dangerous

### Git History Persistence

Git permanently stores commit history.

Even if secret is deleted later:
- previous commits still contain credentials
- repository clones preserve leaked data
- attackers can recover historical secrets

Once secret enters Git:
- it must be considered compromised
- immediate rotation becomes mandatory

---

## Docker Layer Exposure

Docker images are layered and immutable.

Secrets copied during build process may remain accessible through:
- docker history
- image layers
- build cache
- container registry artifacts

Even if secret file is deleted later:
- previous layers may still expose sensitive data

---

## Operational Consequences

Hardcoded secrets create:
- forced image rebuilds
- difficult secret rotation
- deployment delays
- inconsistent environments
- security exposure

Infrastructure loses:
- flexibility
- reproducibility
- operational safety

---

## What ConfigMap Is

ConfigMap is a Kubernetes object for storing non-sensitive runtime configuration.

Typical contents:
- application settings
- feature flags
- service endpoints
- ports
- non-sensitive environment variables

ConfigMaps store data as:
- key-value pairs
- configuration files

---

## How ConfigMap Works

Kubernetes injects ConfigMap data into Pods during runtime.

Injection methods:
- environment variables
- mounted files
- mounted directories

Application code reads configuration dynamically:
- os.getenv()
- configuration files
- mounted runtime paths

Result:
- application image remains unchanged
- environment-specific behavior becomes externalized

---

## What Secret Is

Secret is a Kubernetes object for sensitive information.

Typical contents:
- passwords
- API tokens
- certificates
- encryption keys
- authentication credentials

Secrets support:
- RBAC access control
- restricted visibility
- runtime injection

---

## Secret vs ConfigMap

| Characteristic | ConfigMap | Secret |
|---|---|---|
| Purpose | Non-sensitive config | Sensitive credentials |
| Typical Usage | Ports, flags, URLs | Passwords, API keys |
| Visibility | Broad | Restricted |
| Access Control | Minimal | RBAC-controlled |
| Storage Format | Plain text | Base64 encoded |
| Security Goal | Configuration management | Secret isolation |

Important:
- Base64 encoding is NOT encryption
- Kubernetes Secrets are not полноценный vault solution by default

---

## RBAC And Least Privilege

Production infrastructure must enforce:
- role isolation
- minimal permissions
- controlled secret access

Junior developers should not have permission to:
- read production secrets
- access sensitive namespaces
- retrieve cluster-wide credentials

RBAC limits blast radius during:
- mistakes
- credential leaks
- compromised accounts

---

## Immutable Infrastructure Principle

Production images should:
- build once
- deploy everywhere unchanged

Environment differences must be injected dynamically through:
- ConfigMaps
- Secrets
- environment variables
- external secret providers

Result:
- reproducible deployments
- safer rollbacks
- consistent staging/production behavior

---

## Advanced Production Secret Management

Mature infrastructure often uses external secret systems:
- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- GCP Secret Manager

Kubernetes retrieves secrets dynamically during runtime.

Benefits:
- centralized secret management
- rotation automation
- audit logging
- stronger isolation

---

## Secret Rotation

Production systems must support credential rotation without downtime.

Modern systems reload:
- certificates
- API keys
- access tokens

during runtime.

Goal:
- replace compromised credentials
- avoid full redeployment
- minimize operational disruption

---

## Environment Isolation

Staging and production environments must remain strictly isolated.

Isolation mechanisms:
- separate namespaces
- separate clusters
- separate IAM permissions
- separate secret stores

Purpose:
- prevent accidental cross-environment access
- reduce blast radius
- improve operational safety

---

## Key Learning

- code and configuration must remain separated
- Docker images should stay immutable
- secrets must never be hardcoded into Git or images
- ConfigMaps manage runtime configuration
- Secrets manage sensitive credentials
- Base64 is not encryption
- RBAC enforces least privilege access
- mature systems support runtime secret rotation
- production environments require strict isolation
