# Incident Analysis — Week 8 Day 1

## Scenario

Team experiences deployment inconsistencies:

- application works locally but fails on server
- Python versions differ between environments
- dependencies behave differently
- staging and production produce different results

CTO requests environment standardization.

---

## What Problem Is Happening

This is an example of Environment Drift.

Application behavior depends on:
- source code
- runtime version
- libraries
- system packages
- OS configuration
- environment variables

When these layers differ between environments:
- behavior becomes unpredictable
- deployments become unreliable

---

## Why "Works on My Machine" Is Dangerous

Local success does not guarantee production compatibility.

Problems:
- different runtime versions
- incompatible dependencies
- hidden system-level assumptions

Consequences:
- deployment failures
- unstable releases
- difficult debugging
- non-reproducible environments

Local machine must not be the source of truth.

---

## What Containerization Is

Containerization is process isolation at operating system level.

Containers package:
- application code
- dependencies
- runtime
- configuration

into a reproducible isolated environment.

Containers use Linux kernel features:
- namespaces
- cgroups

to isolate:
- filesystem
- processes
- networking
- resource usage

Unlike virtual machines:
- containers do not require full guest OS
- containers are lightweight and faster to start

---

## Why Docker Is Better Than Manual Server Setup

### 1. Immutable Infrastructure

Docker image is a fixed snapshot of the application environment.

Same image:
- tested in staging
- deployed in production

without changes.

---

### 2. Dependency Isolation

Different applications can use:
- different Python versions
- different libraries

on the same host safely.

---

### 3. Reproducibility

Application behaves consistently:
- locally
- in CI
- in staging
- in production

---

### 4. Disposable Infrastructure

Containers are temporary and replaceable.

Instead of manually fixing servers:
- broken container is destroyed
- new identical container is created

---

## Mature Container Deployment Workflow

### 1. Build

Developer writes Dockerfile.

CI system builds Docker image.

---

### 2. Tagging

Image receives immutable version tag.

Examples:
- api:v1.4.2
- api:commit-a82f91

Avoid using:
- latest

for production deployments.

---

### 3. Push

Image is uploaded to container registry.

---

### 4. Test

Same image is tested in staging environment.

---

### 5. Deploy

Exactly the same image is deployed to production.

Principle:
Build once, deploy many.

---

## Key Learning

- Application includes its environment
- Environment drift causes unreliable deployments
- Containers improve reproducibility and isolation
- Docker enables immutable infrastructure
- Production deployments require consistent runtime environments
