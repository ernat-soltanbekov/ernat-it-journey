# Incident Analysis — Week 9 Day 2

## Scenario

Team deployed a new API version into Kubernetes cluster.

Deployment completed successfully:
- Pods entered `Running` state
- restart count remained zero
- CPU and memory metrics looked healthy

However, production users experienced severe instability:
- intermittent 502 errors
- high p99 latency during rollout
- traffic routed into Pods that were still initializing
- requests interrupted during Pod termination
- temporary service degradation during rolling updates

Kubernetes events showed:
- readiness probe failures
- unstable rollout behavior

CTO concluded:
The team does not understand the difference between a running process and a production-ready service.

---

## What Problem Is Happening

The system suffers from premature traffic routing and unsafe Pod lifecycle handling.

During rolling deployment:
- Kubernetes launches new Pods
- container process starts successfully
- Pod enters `Running` state

But application initialization is not finished yet.

The application may still be:
- establishing database connections
- warming caches
- initializing thread pools
- loading configuration
- preparing internal state

Despite this:
- traffic already reaches the Pod
- clients receive failures
- ingress returns 502 errors

At the same time:
- old Pods may terminate too aggressively
- active requests become interrupted
- user sessions break during rollout

Result:
- unstable deployments
- temporary outages
- elevated latency
- failed client requests

---

## Why `Running` Status Guarantees Nothing

`Running` only means:
- container process exists
- main PID is alive
- container did not exit

Kubernetes does not understand:
- application logic
- initialization state
- dependency readiness
- service responsiveness

A Pod may remain `Running` while:
- application is deadlocked
- database connectivity is broken
- startup initialization is incomplete
- internal worker pool is exhausted
- application returns only HTTP 500 responses

From Kubernetes perspective:
- process alive = Running

From user perspective:
- service unavailable

This creates critical mismatch between infrastructure state and real service health.

---

# Kubernetes Probes

Kubernetes uses probes to understand actual application state.

Probes may execute:
- HTTP requests
- TCP socket checks
- commands inside container

There are three major probe types.

---

## Startup Probe

### Purpose

Protect slow-starting applications.

Some services require:
- cache warm-up
- migrations
- JVM startup
- model loading
- dependency initialization

Startup probe delays other probes until initialization completes.

---

### Mechanism

While Startup Probe fails:
- Readiness Probe disabled
- Liveness Probe disabled

If Startup Probe eventually succeeds:
- normal lifecycle checks begin

If Startup Probe fails repeatedly:
- container restarted

---

### Purpose In Production

Prevents:
- premature restarts
- false liveness failures
- crash loops during startup

---

## Readiness Probe

### Purpose

Determines whether Pod may receive traffic.

Main question:
- "Can this Pod safely serve users right now?"

---

### Mechanism

If readiness succeeds:
- Pod added into Service Endpoints
- ingress/load balancer may send traffic

If readiness fails:
- Pod removed from routing
- traffic stops immediately

Important:
- Pod is NOT restarted
- container continues running

---

### Typical Readiness Checks

- database connectivity
- Redis availability
- dependency responsiveness
- internal queue saturation
- application warm-up completion

---

## Liveness Probe

### Purpose

Detect unrecoverable application state.

Main question:
- "Is process permanently broken?"

---

### Mechanism

If Liveness Probe fails repeatedly:
- Kubernetes restarts container

This acts as automatic recovery mechanism.

---

### Typical Liveness Checks

- event loop responsiveness
- web server responsiveness
- deadlock detection
- internal heartbeat

---

## Important Distinction

Liveness should NOT depend on external business dependencies.

Bad example:
- liveness fails because database unavailable

Result:
- Kubernetes restarts healthy application
- restart storm begins

Liveness must answer:
- "Should this process be restarted?"

NOT:
- "Is downstream infrastructure healthy?"

---

## How Misconfigured Probes Destroy Production

Incorrect probes may trigger cascading failures.

Classic production scenario:

1. Database becomes slow
2. API latency increases
3. Liveness timeout too aggressive
4. Kubernetes restarts API Pods
5. Remaining Pods receive more traffic
6. Latency grows further
7. More probes fail
8. More Pods restart
9. Entire cluster destabilizes

This creates:
- probe flapping
- restart storms
- deployment collapse

---

## CrashLoopBackOff

If Pod repeatedly fails startup or liveness checks:
- Kubernetes enters CrashLoopBackOff state

Behavior:
- restart
- fail
- exponential delay
- restart again

Purpose:
- prevent infinite aggressive restart loops

---

## Warm-Up Phase

Applications often require initialization time before becoming operational.

Examples:
- loading ML models
- opening DB pools
- cache hydration
- JIT compilation
- dependency synchronization

Traffic during warm-up causes:
- timeouts
- 502 responses
- poor latency

Readiness probes protect against premature traffic exposure.

---

## Graceful Shutdown

When Kubernetes removes Pod:
- kubelet sends SIGTERM

Application should:
1. fail readiness probe
2. stop receiving new traffic
3. finish active requests
4. close resources safely
5. terminate gracefully

Without graceful shutdown:
- active requests interrupted
- users receive errors
- transactions may break

---

## Traffic Draining

Traffic draining means:
- removing Pod from load balancing
- while allowing existing requests to finish

This prevents:
- abrupt session termination
- broken uploads
- incomplete transactions

---

## terminationGracePeriodSeconds

Kubernetes waits limited time after SIGTERM before force killing container.

This parameter defines:
- graceful shutdown window

If too small:
- requests interrupted

If too large:
- deployments become slow

---

## Production-Grade Health Checking

Reliable production systems require:

### Separate Probe Endpoints

#### Liveness Endpoint

Example:
- `/healthz/live`

Characteristics:
- lightweight
- dependency-independent
- checks only core process health

---

#### Readiness Endpoint

Example:
- `/healthz/ready`

Characteristics:
- verifies critical dependencies
- validates service readiness
- controls traffic admission

---

### Conservative Thresholds

Avoid aggressive probe settings.

Recommended:
- retries before restart
- reasonable timeout windows
- startup delays
- failure thresholds

Purpose:
- tolerate temporary slowdowns
- avoid cascading restarts

---

### Graceful Lifecycle Management

Applications must support:
- SIGTERM handling
- connection draining
- readiness transition
- safe termination

---

### Rolling Update Safety

During deployment:
- new Pods become ready first
- old Pods removed gradually
- traffic shifts progressively

Purpose:
- zero-downtime deployment
- stable rollout behavior

---

## Key Learning

- Running does not mean ready
- probes define operational lifecycle
- readiness controls traffic routing
- liveness controls restart behavior
- startup probe protects initialization phase
- bad probes can destroy production stability
- graceful shutdown prevents request loss
- deployment safety depends on lifecycle orchestration
