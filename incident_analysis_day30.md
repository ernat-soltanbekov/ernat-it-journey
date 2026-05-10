# Incident Analysis — Week 8 Day 2

## Scenario

Team built a Docker image for API deployment.

Problems observed:
- image size reached 4.7 GB
- container startup time became very slow
- CI/CD pipeline slowed down significantly
- builds frequently invalidated cache
- production nodes accumulated large unused images

CTO concluded that Docker was being used inefficiently.

---

## What Problem Is Happening

The team treats Docker image as a generic file archive instead of an optimized deployment artifact.

Large image size usually indicates:
- unnecessary files copied into image
- oversized base image
- duplicated dependencies
- inefficient build process
- poor Docker layer usage

Result:
- slower builds
- slower deployments
- increased infrastructure overhead

---

## Why Large Docker Images Are Dangerous

### 1. Slow Delivery

Large images require more time to:
- build
- upload
- download
- deploy

This increases lead time during releases and incident recovery.

---

### 2. Network Pressure

In production systems:
- multiple nodes pull images simultaneously
- autoscaling increases image downloads
- rolling deployments multiply traffic

Huge images slow down rollout speed.

---

### 3. Storage Overhead

Container registries and production nodes accumulate large image layers.

Result:
- wasted disk space
- higher infrastructure costs

---

### 4. Security Risk

More packages inside image means:
- larger attack surface
- more vulnerabilities
- unnecessary tools available inside runtime container

---

## What Docker Layers Are

Each Dockerfile instruction creates a read-only filesystem layer.

Examples:
- FROM
- RUN
- COPY

Docker stores:
- filesystem differences between layers

instead of full copies.

---

## Layer Caching Mechanism

If a layer has not changed:
- Docker reuses cached version

If one layer changes:
- all following layers must rebuild

This behavior is called:
- cache invalidation

---

## Why Dockerfile Command Order Matters

Incorrect order example:

```dockerfile
COPY . .
RUN pip install -r requirements.txt
````

Problem:

* every source code change invalidates dependency cache
* dependencies reinstall every build

---

Correct approach:

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
```

Result:

* dependency layer reused
* faster rebuilds

---

## Production-Ready Docker Image Principles

### 1. Minimal Base Images

Use:

* alpine
* slim

instead of full operating system images.

---

### 2. .dockerignore

Exclude unnecessary files:

* .git
* logs
* **pycache**
* local virtual environments
* temporary files

---

### 3. Multi-Stage Builds

Separate:

* build environment
* runtime environment

Build stage contains:

* compilers
* build tools
* dependencies

Runtime stage contains only:

* application
* required runtime libraries

Result:

* smaller image
* reduced attack surface

---

### 4. Non-Root Execution

Containers should not run as root.

Use:

```dockerfile
USER appuser
```

to improve runtime security.

---

### 5. Minimal Runtime Environment

Production image should contain only what is required to run application.

Avoid:

* compilers
* package managers
* git
* test tools

inside runtime container.

---

## Key Learning

* Docker images are deployment artifacts, not file archives
* Layer caching directly affects CI/CD performance
* Smaller images improve deployment speed and reliability
* Multi-stage builds reduce runtime overhead
* Production containers should be minimal and secure

