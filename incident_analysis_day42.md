# Incident Analysis — Week 9 Day 7

## Scenario

Production Kubernetes platform using Service Mesh architecture experienced severe user-facing latency degradation.

Architecture:

```text
Clients
  ↓
Ingress
  ↓
Service Mesh (Envoy sidecars)
  ↓
Microservices
  ↓
PostgreSQL
```

Observed symptoms:
- application feels slow
- random freezes
- partial page loading
- intermittent reconnects
- requests hanging for multiple seconds

Infrastructure dashboards appeared mostly healthy:
- CPU normal
- memory normal
- Pods healthy
- readiness probes passing
- node health normal
- database healthy

However latency metrics showed severe degradation:

```text
P95 latency:
300ms → 9s

P99 latency:
500ms → 25s
```

Mesh telemetry showed:
- upstream request timeout
- upstream reset before response
- downstream disconnect

Root cause involved:
- latency amplification
- timeout propagation
- retry amplification
- service mesh retry behavior

rather than:
- hard infrastructure failure.

---

# Service Mesh Architecture

Service Mesh introduces dedicated network layer between services.

Common implementations:
- Istio
- Linkerd

Mesh uses:
- sidecar proxies

typically:
- Envoy

Each Pod receives:
- local proxy container

Traffic flow becomes:

```text
Service A
→ Envoy sidecar
→ network
→ destination sidecar
→ Service B
```

This architecture enables:
- traffic policies
- retries
- TLS
- observability
- circuit breaking
- traffic shaping

Mesh primarily controls:
- east-west traffic

meaning:
- service-to-service communication inside cluster.

---

# Why Dashboards Appeared Healthy

Infrastructure health does not equal user experience.

Dashboards commonly emphasize:
- averages
- infrastructure availability
- resource consumption

while missing:
- tail latency
- queueing delay
- degraded responsiveness
- retry amplification

System may appear:
- operational internally

while users experience:
- unusable application behavior.

---

# P95 and P99 Latency

Latency percentiles describe:
- worst-case request behavior.

P95:
- 95% requests faster than value
- 5% slower

P99:
- 99% requests faster than value
- 1% slower

Tail latency critical because:
- users experience slowest requests directly

Averages often hide production degradation.

Example:

```text
95 requests = 50ms
5 requests = 25s
```

Average remains deceptively acceptable.

User experience already severely degraded.

---

# Timeout Propagation

Microservice chains create:
- distributed waiting dependencies

Example:

```text
Frontend
→ Service A
→ Service B
→ Service C
→ Database
```

Latency at lower layer propagates upward.

Poor timeout hierarchy creates:
- zombie requests
- wasted compute
- queue growth
- unnecessary resource occupation

Correct timeout structure requires:
- shorter downstream deadlines

Example:

```text
Frontend = 30s
Service A = 25s
Service B = 20s
Database = 10s
```

Timeout budgets must shrink deeper into dependency chain.

---

# Retry Amplification

Retries multiply traffic volume during degradation.

Example:

```text
Request fails
→ service retries 3x
→ downstream retries 3x
→ mesh retries 3x
```

Traffic amplification becomes multiplicative.

Small latency problem transforms into:
- large concurrency explosion

Retries commonly worsen partially degraded systems.

---

# Positive Feedback Loop

Distributed systems frequently collapse through self-amplifying latency loops.

Flow:

```text
slow dependency
→ retries
→ more traffic
→ queue growth
→ higher latency
→ more retries
→ cascading degradation
```

This creates:
- nonlinear failure escalation.

---

# Tail Latency Collapse

Small latency increases produce:
- queue accumulation

Queueing increases:
- request waiting time

Waiting time triggers:
- retries
- additional concurrency

Additional concurrency further increases:
- queue pressure

Eventually:
- latency explodes exponentially

This phenomenon called:
- tail latency collapse

Distributed systems often fail through:
- latency amplification

rather than:
- hard crashes.

---

# Sidecar Proxy Overhead

Service mesh sidecars introduce:
- additional network hops
- TLS overhead
- proxy processing
- buffering
- queueing
- retry coordination

Request path becomes significantly longer.

Each proxy may maintain:
- worker pools
- connection pools
- retry queues
- timeout policies

Mesh abstraction therefore introduces:
- operational overhead
- latency sensitivity

especially under degraded conditions.

---

# Head-of-Line Blocking

Slow requests occupy:
- worker threads
- queue slots
- connections
- stream capacity

Fast requests arriving later become blocked behind:
- stalled requests

This phenomenon called:
- head-of-line blocking

Shared queues amplify latency spread across entire system.

---

# Retry Budgets

Unlimited retries dangerous during degradation.

Retry budgets define:
- maximum retry allowance

Purpose:
- prevent retry storms
- avoid traffic amplification
- preserve downstream stability

Production systems should:
- aggressively limit retries during incidents.

---

# Circuit Breaking Inside Service Mesh

Circuit breakers protect downstream services.

Instead of:
- endlessly retrying slow upstreams

proxy temporarily:
- stops forwarding traffic

Benefits:
- protects overloaded services
- prevents retry amplification
- stabilizes latency

Mesh-level circuit breaking critical for:
- distributed survivability.

---

# Why Logs Were Mostly Empty

Many latency failures occur:
- before application logic executes

Problems may happen inside:
- proxy queues
- connection pools
- sidecar timeouts
- mesh retries

Application therefore:
- never sees explicit failure

This creates:
- observability blind spots

Infrastructure appears healthy while:
- users experience severe degradation.

---

# Why Readiness Probes Failed To Detect Issue

Readiness probes typically verify:
- process alive
- port responsive
- basic endpoint availability

They rarely measure:
- queue depth
- latency saturation
- retry amplification
- degraded responsiveness

System may remain:
- technically ready

while operationally overloaded.

---

# Observability Blind Spots

Traditional monitoring often measures:
- infrastructure metrics

instead of:
- end-user latency
- queueing delay
- distributed retries
- timeout propagation

Critical production failures may remain invisible if:
- observability focuses only on resource usage.

---

# Investigation Process

## Mesh Telemetry

Inspect:
- retry rates
- timeout counts
- upstream latency
- downstream resets

Important Envoy metrics:
- upstream_rq_timeout
- upstream_rq_retry
- upstream_cx_overflow

---

# Distributed Tracing

Use:
- Jaeger
- Tempo
- OpenTelemetry

Purpose:
- identify slow spans
- locate latency accumulation
- visualize timeout propagation

Tracing essential for:
- distributed latency debugging.

---

# Tail Latency Monitoring

Prioritize:
- P95
- P99
- queue duration
- retry metrics

Avoid relying exclusively on:
- averages.

---

# Production Mitigation Plan

## Short-Term Stabilization

- reduce retry counts
- shorten timeout windows
- disable aggressive mesh retries
- activate circuit breaking
- reduce queue sizes
- shed excess traffic

Goal:
- stop latency amplification loops.

---

# Long-Term Improvements

## Timeout Hierarchy

Design:
- strict deadline propagation
- shrinking downstream timeouts

Avoid:
- orphaned background requests.

---

# Retry Governance

Implement:
- retry budgets
- adaptive retry policies
- retry jitter

Prevent:
- self-generated overload amplification.

---

# Queue Isolation

Separate:
- critical traffic
- expensive requests
- latency-sensitive operations

Reduce:
- head-of-line blocking.

---

# Observability Improvements

Monitor:
- tail latency
- distributed tracing
- queue depth
- retry amplification
- timeout propagation

Focus on:
- user experience metrics

not only:
- infrastructure health.

---

# Architectural Lessons

Distributed systems frequently degrade through:
- latency amplification
- retry multiplication
- queue saturation
- timeout propagation

rather than:
- immediate crashes.

Healthy infrastructure metrics do not guarantee:
- healthy user experience.

---

# Key Learning

- averages hide tail latency collapse
- retries amplify distributed failures
- latency propagates across dependency chains
- service meshes introduce operational overhead
- readiness probes do not measure responsiveness
- observability blind spots hide degraded UX
- distributed systems often fail progressively through queues and retries
