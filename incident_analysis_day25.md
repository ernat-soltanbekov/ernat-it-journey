# Incident Analysis — Week 7 Day 4

## Scenario
User reports:
"System behaves inconsistently — sometimes fast, sometimes very slow or failing. Hard to reproduce."

---

## Observations

- CPU and RAM usage are normal
- Error rate fluctuates
- Latency varies significantly:
  - p95 ≈ 200ms
  - p99 ≈ 5s
- Logs show no obvious errors

---

## What Is Happening

- System experiences tail latency issues
- A small percentage of requests take significantly longer
- Average metrics hide these slow requests

→ Result:
Most users are unaffected, but some experience severe delays

---

## Core Problem

- Lack of end-to-end visibility
- Logs are unstructured and disconnected
- No way to trace a single request across services

---

## Solutions

### 1. Structured Logging + Correlation ID

- Assign unique ID to each request
- Pass it through all services and components
- Log structured data (not plain text)

Fields:
- request_id
- user_id
- endpoint
- latency
- status

Result:
- Enables tracing request flow through logs

---

### 2. Metrics with Percentiles

- Track p50, p95, p99 latency
- Break down metrics by:
  - endpoint
  - service
  - dependency

Result:
- Reveals hidden performance issues
- Identifies problematic components

---

### 3. Distributed Tracing

- Split request into spans
- Track time spent in each component:
  - API
  - database
  - external services

Result:
- Full visibility of request lifecycle
- Pinpoints exact bottlenecks

---

## Key Learning

- Average metrics can hide real problems
- Tail latency significantly impacts user experience
- Observability is essential for debugging complex systems
- Visibility must be built into system design
