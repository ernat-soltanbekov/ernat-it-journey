# Incident Analysis — Week 7 Day 7

## Scenario

A new API version was deployed on Friday evening.

After deployment:

- latency increased x4
- p99 latency reached 12 seconds
- CPU usage rose to 95%
- some users received 502/504 errors
- rollback was performed only after 40 minutes

Unit tests and staging environment showed no critical issues before release.

---

## What Happened

The new version reduced system throughput under real production load.

Possible causes:
- inefficient database query
- memory leak
- blocking operation
- thread/resource exhaustion

As latency increased:
- requests accumulated
- workers became saturated
- CPU spent resources on context switching
- reverse proxy (Nginx) started returning 502/504

Result:
System entered resource saturation state.

---

## Why Staging Did Not Reveal the Problem

### 1. Insufficient Load
Staging environment had very low concurrency compared to production traffic.

Problems such as:
- lock contention
- queue buildup
- thread starvation

only appear under heavy parallel load.

---

### 2. Different Dataset Size
Production database contained significantly more records.

Queries that are fast on small datasets may become extremely slow on large tables.

---

### 3. Different Traffic Shape
Production traffic contains:
- bursts
- uneven load distribution
- hot endpoints
- cache invalidation patterns

These conditions were absent in staging.

---

## Main Architectural Mistake

Deployment strategy was:
- all-at-once

All production instances were updated simultaneously.

Result:
- no blast radius reduction
- bug immediately affected all users

Additionally:
- no automatic rollback mechanism existed

Rollback depended entirely on manual human reaction.

---

## How to Reduce Deployment Risk

### 1. Canary Deployment

Deploy new version to a small percentage of instances or users.

Example:
- 1%
- 5%
- 25%
- 50%
- 100%

Monitor:
- latency
- error rate
- CPU
- saturation

Rollback immediately if metrics degrade.

---

### 2. Feature Flags

Deploy code in disabled state.

Enable feature gradually for selected users without redeployment.

Result:
- safer rollout
- instant disable capability

---

### 3. Load Testing Before Production

Use tools such as:
- k6
- Locust
- Gatling

Test:
- throughput
- concurrency
- latency degradation

before real deployment.

---

## What Mature Production Deployment Looks Like

### Blue/Green Deployment

Maintain two identical environments:
- Blue (current stable)
- Green (new version)

Switch traffic only after validation.

Rollback:
- instant traffic switch back

---

### Health Checks

System continuously verifies:
- service availability
- response time
- dependency health

Deployment stops automatically if checks fail.

---

### Deployment Gates

Automatic rollout stop when:
- p99 latency exceeds threshold
- error rate spikes
- saturation increases

---

### Automated Rollback

If deployment degrades system metrics:
- rollback starts automatically
- stable version restored without waiting for manual intervention

---

## Key Learning

- Production deployment is risk management
- Staging cannot fully reproduce production behavior
- Blast radius must be minimized
- Progressive delivery reduces deployment risk
- Rollback must be automated whenever possible
