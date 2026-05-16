# Incident Analysis — Week 9 Day 1

## Scenario

Team deployed API into Kubernetes cluster.

System worked correctly on staging.

However, production environment started showing severe instability:
- Pods periodically restarted
- requests terminated unexpectedly
- Kubernetes events showed `OOMKilled`
- p99 latency increased sharply before restarts
- some Pods disappeared completely under load
- entire node became slow and unstable

Observed metrics:
- CPU usage: 45%
- Node RAM usage: 98%
- Kubernetes events:
  - OOMKilled
  - Evicted

CTO concluded that the team does not understand Kubernetes resource management and memory isolation.

---

## What Problem Is Happening

The cluster entered memory overcommitment state.

Production traffic caused applications to consume significantly more RAM than during staging tests.

As node memory approached exhaustion:
- Linux kernel activated Out Of Memory protection mechanisms
- Kubernetes started eviction procedures
- node stability degraded

System behavior became unstable because memory is an incompressible resource.

Unlike CPU starvation:
- memory exhaustion cannot be delayed safely
- processes must be terminated to protect node survival

Result:
- request interruptions
- Pod restarts
- node degradation
- cascading instability

---

## What OOMKilled Actually Is

OOMKilled is not generated directly by Kubernetes.

It originates from Linux kernel memory protection mechanisms.

Kubernetes relies on Linux cgroups (control groups) to isolate container resources.

Mechanism:
1. Kubernetes defines memory limits for container
2. Linux cgroups enforce those limits
3. Process attempts to allocate memory beyond limit
4. Kernel denies allocation
5. Linux OOM Killer selects victim process
6. Process receives SIGKILL
7. Container exits with code 137
8. Kubernetes reports state as OOMKilled

Result:
- container terminates immediately
- active requests are interrupted
- Pod may restart depending on restart policy

---

## Container-Level OOM vs Node-Level OOM

### Container-Level OOM

Occurs when:
- container exceeds its cgroup memory limit

Result:
- specific container dies
- node remains operational

---

### Node-Level OOM

Occurs when:
- total node memory becomes exhausted

Result:
- Linux kernel may kill:
  - application Pods
  - kubelet
  - container runtime
  - system services

This creates catastrophic node instability.

---

## Why Memory Pressure Is More Dangerous Than CPU Pressure

CPU is a compressible resource.

When CPU becomes overloaded:
- processes slow down
- latency increases
- Linux throttles execution time

Application usually remains alive.

---

Memory is an incompressible resource.

When memory becomes unavailable:
- allocations fail immediately
- operating system cannot delay allocation safely
- kernel must terminate processes

Result:
- abrupt request failures
- broken client sessions
- Pod crashes
- infrastructure instability

---

## What Requests Are

Requests define guaranteed resource reservation.

Kubernetes Scheduler uses requests during Pod placement decisions.

Example:
- Pod requests 2 GB RAM
- Scheduler places Pod only on node with enough allocatable memory

Purpose:
- prevent uncontrolled overcommitment
- improve placement predictability
- reserve minimum required resources

Requests affect:
- scheduling
- QoS classification
- cluster capacity planning

---

## What Limits Are

Limits define maximum allowed resource consumption.

Linux cgroups enforce limits strictly.

If container exceeds memory limit:
- allocation fails
- OOM Killer may terminate process

Purpose:
- prevent noisy neighbor problems
- isolate workloads
- protect node stability

---

## Kubernetes QoS Classes

Kubernetes assigns QoS (Quality of Service) classes based on requests and limits.

---

### Guaranteed

Requirements:
- requests == limits
- for both CPU and memory

Characteristics:
- highest stability
- lowest eviction priority
- strongest isolation

Used for:
- critical APIs
- ingress controllers
- production databases

---

### Burstable

Requirements:
- requests defined
- limits higher than requests

Characteristics:
- flexible scaling behavior
- moderate protection
- moderate eviction risk

Most common production class.

---

### BestEffort

Requirements:
- no requests
- no limits

Characteristics:
- no guarantees
- highest eviction priority
- extremely dangerous in production

BestEffort Pods are usually killed first during node pressure.

---

## What Eviction Is

Eviction is Kubernetes node survival mechanism.

When node experiences memory pressure:
- kubelet proactively removes Pods

Purpose:
- protect node stability
- avoid full node crash
- preserve critical workloads

Eviction occurs before total node failure whenever possible.

---

## Noisy Neighbor Problem

Without limits:
- one workload may consume excessive resources
- neighboring applications become unstable

This is called noisy neighbor effect.

Limits and QoS isolation reduce:
- resource starvation
- cross-service instability
- unpredictable failures

---

## Production-Grade Resource Management

Stable production infrastructure requires:

### Proper Requests And Limits

Every critical workload must define:
- CPU requests
- memory requests
- CPU limits
- memory limits

BestEffort workloads should not exist in production.

---

### Guaranteed QoS For Critical Services

Critical components should use:
- Guaranteed QoS
- predictable memory boundaries
- stable scheduling behavior

---

### Node Allocatable Reservation

Part of node resources must remain reserved for:
- kubelet
- container runtime
- Linux kernel
- system daemons

Without reservation:
- node itself may become unstable

---

### Horizontal Scaling

Horizontal Pod Autoscaler (HPA) should scale workloads based on:
- CPU
- memory
- traffic patterns

Purpose:
- distribute load
- avoid memory saturation
- reduce risk of OOM events

---

### Observability

Production monitoring must track:
- memory usage
- memory growth trends
- eviction events
- OOMKilled frequency
- p95/p99 latency
- node pressure signals

---

## Key Learning

- memory exhaustion causes process termination
- Kubernetes relies on Linux cgroups for isolation
- OOMKilled originates from Linux kernel protection
- requests affect scheduling decisions
- limits enforce hard resource boundaries
- BestEffort Pods are dangerous in production
- QoS classes influence eviction priority
- memory pressure is more dangerous than CPU pressure
- stable infrastructure requires predictable resource governance
