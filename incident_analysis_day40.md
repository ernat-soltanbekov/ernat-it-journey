# Incident Analysis — Week 9 Day 5

## Scenario

Company deployed microservice platform behind:

```text
Users
  ↓
NGINX Ingress
  ↓
API Gateway
  ↓
Microservices
```

During major marketing campaign:
- incoming traffic increased 15x
- login endpoint became unstable
- clients received:
  - 429 Too Many Requests
  - 502 Bad Gateway
  - 504 Gateway Timeout

Symptoms:
- login requests timing out
- aggressive client retries
- gateway CPU saturation
- stable memory usage
- healthy downstream services
- healthy PostgreSQL
- healthy Kubernetes nodes

Initial engineering assumption:
- Kubernetes networking failure

Actual root cause:
- retry storm combined with API Gateway CPU exhaustion

---

# What Is API Gateway

API Gateway acts as centralized entry point for client traffic.

Gateway responsibilities commonly include:
- authentication
- JWT validation
- request routing
- TLS termination
- logging
- rate limiting
- request aggregation
- observability
- traffic policies

Gateway centralizes cross-cutting concerns for distributed systems.

---

# Why Gateway Became Bottleneck

Ingress layer continued forwarding traffic normally.

Gateway became overloaded because:
- authentication endpoints were CPU expensive
- login traffic increased sharply
- retries amplified request volume
- gateway processed excessive concurrent requests

Result:
- request queues expanded
- latency increased
- timeout cascade started

Healthy downstream services did not help because many requests never reached them.

Platform availability depends on:
- entire request path
not only:
- backend service health

---

# 429 vs 502 vs 504

## 429 Too Many Requests

Gateway intentionally rejected traffic because:
- rate limit exceeded
- system attempted self-protection

Meaning:
- gateway still operational
- overload protection activated

---

# 502 Bad Gateway

Gateway received invalid upstream response.

Possible causes:
- upstream connection reset
- broken TCP connection
- malformed upstream response
- exhausted connection pools
- upstream crash during request

502 does not necessarily mean gateway itself crashed.

---

# 504 Gateway Timeout

Gateway successfully forwarded request but upstream response exceeded timeout limit.

Meaning:
- request processing exceeded configured deadline

---

# Retry Storm

Mobile clients aggressively retried failed requests.

Flow:

```text
slow responses
→ client retries
→ higher traffic
→ more latency
→ additional retries
→ cascading overload
```

Traffic amplification transformed:
- 15x traffic spike
into:
- much larger effective load

Retry storms commonly destroy partially degraded systems.

---

# Thundering Herd Problem

Clients retried requests simultaneously after receiving timeouts.

Without randomized retry delays:
- thousands of clients synchronized retry behavior
- traffic arrived in massive waves

This phenomenon called:
- thundering herd problem

Synchronized retries amplify overload conditions dramatically.

---

# Exponential Backoff With Jitter

Production mobile clients should implement:
- exponential backoff
- randomized jitter

Example:

```text
1s
2s
4s
8s
```

with random delay offsets.

Purpose:
- desynchronize retries
- smooth traffic spikes
- reduce synchronized overload

Jitter prevents retry synchronization waves.

---

# Why CPU Saturation Is Dangerous

Memory exhaustion usually produces:
- OOMKill
- fast restart
- visible failure state

CPU saturation more dangerous because:
- process remains alive
- latency grows continuously
- queues expand
- timeout cascade spreads
- partial availability appears

System becomes:
- alive but operationally nonfunctional

This creates zombie-state infrastructure.

---

# Request Queue Collapse

Under CPU pressure:
- incoming requests accumulate in queues

Growing queues produce:
- additional latency
- memory pressure
- timeout amplification

Eventually:
- requests timeout before execution even begins

Infinite queue growth destabilizes entire platform.

Reliable systems use:
- bounded queues
- concurrency limits
- controlled rejection

instead of:
- unbounded waiting.

---

# Backpressure

Backpressure means controlled refusal of excess work.

System intentionally slows or rejects traffic when overloaded.

Mechanisms include:
- bounded queues
- concurrency caps
- adaptive throttling
- connection limits
- request rejection

Purpose:
- prevent total system collapse

Backpressure protects latency and platform survivability.

---

# Load Shedding

Load shedding intentionally drops requests during overload.

Principle:

```text
better partial availability
than total failure
```

Examples:
- rejecting anonymous traffic
- disabling noncritical features
- prioritizing authentication traffic
- rejecting expensive endpoints

Production systems often reduce functionality temporarily to survive spikes.

---

# Why Healthy Services Did Not Save Platform

Microservices and databases remained healthy because:
- gateway failed first

Architecture contained centralized choke point.

Failure at gateway layer prevented requests from reaching:
- services
- databases

Distributed platform availability depends on:
- weakest critical component

not:
- average component health.

---

# Autoscaling Limitations

Horizontal Pod Autoscaler cannot instantly solve overload.

Reasons:

---

# Scaling Delay

New Pods require:
- scheduling
- image pull
- startup
- readiness checks

Scaling may require:
- tens of seconds

Retry storms escalate within seconds.

---

# Metrics Delay

HPA reacts using delayed metrics pipeline.

Metrics collection includes:
- scrape intervals
- aggregation
- stabilization windows

Autoscaling always reactive.

---

# Persistent Bottlenecks

Additional Pods may not solve:
- database connection exhaustion
- TLS bottlenecks
- auth bottlenecks
- load balancer limits
- network saturation

Scaling compute does not automatically remove architectural bottlenecks.

---

# Architectural Mistakes

Team made several critical mistakes.

---

# Weak Retry Strategy

Mobile applications aggressively retried requests without:
- exponential backoff
- jitter
- retry limits

Clients effectively behaved as self-generated DDoS traffic.

---

# Poor Protection Placement

Rate limiting executed too deep in request path.

Gateway CPU spent resources:
- validating
- parsing
- authenticating

before rejecting excess traffic.

Protection should begin:
- as early as possible

preferably:
- at ingress edge.

---

# Shared Critical Resources

Heavy authentication traffic shared same gateway infrastructure with normal requests.

Expensive login processing degraded entire platform.

Critical endpoints require:
- isolation
- prioritization
- dedicated scaling strategy

---

# Production-Grade Mitigation Plan

## Client Layer

Implement:
- exponential backoff
- randomized jitter
- retry caps
- smarter retry conditions

Prevent synchronized retry storms.

---

# Ingress Layer

Deploy:
- edge rate limiting
- connection limiting
- IP throttling
- request filtering

Reject malicious or excessive traffic before gateway layer.

---

# Gateway Layer

Implement:
- circuit breakers
- bounded queues
- concurrency limits
- load shedding
- adaptive throttling

Protect CPU and latency stability.

---

# Infrastructure Layer

Configure:
- HPA based on CPU
- proactive scaling thresholds
- warm standby capacity
- gateway isolation

Avoid scaling only after saturation already begins.

---

# Architectural Principles

Reliable traffic systems require:
- layered defense
- retry control
- bounded concurrency
- overload protection
- graceful degradation
- traffic desynchronization
- choke-point awareness

---

# Key Learning

- healthy services do not guarantee healthy platform
- retries can amplify outages catastrophically
- synchronized clients create thundering herd effects
- CPU saturation causes latency collapse
- autoscaling reacts slower than traffic spikes
- backpressure and load shedding protect survivability
- gateways are common distributed-system choke points
- production systems must reject excess work intentionally
