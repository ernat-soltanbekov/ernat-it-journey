# Day 54 — Kubernetes Memory Pressure and Pod Evictions

## Incident Summary

A Kubernetes production cluster began experiencing service degradation during normal operations.

Observed symptoms:

- Intermittent HTTP 503 responses
- Unexpected pod restarts
- Increasing number of Evicted pods
- Cluster-wide CPU and memory utilization appeared healthy
- Several nodes reported MemoryPressure=True

Infrastructure metrics:

```text
Cluster CPU: 45%
Cluster Memory: 55%
```

However, individual nodes showed:

```text
Memory Usage:
92%
95%
97%
98%
```

Kubelet logs contained:

```text
eviction manager:
attempting to reclaim memory
```

followed by:

```text
evicting pod frontend-api
evicting pod recommendation-worker
```

---

## Root Cause

The cluster suffered from memory overcommit caused by inaccurate resource requests.

Most workloads declared:

```yaml
resources:
  requests:
    cpu: 100m
    memory: 128Mi
```

while real application consumption was:

```text
1.5–2.0 GiB RAM
```

for multiple Java services.

The Kubernetes scheduler places workloads according to declared requests rather than actual runtime consumption.

As a result:

```text
Low Requests
        ↓
Node Overpacking
        ↓
Memory Pressure
        ↓
Pod Evictions
```

The cluster appeared healthy on average while individual nodes became overloaded.

---

## Resource Concepts

### Requests

Guaranteed resources reserved by the scheduler.

Used during placement decisions.

Example:

```yaml
requests:
  memory: 128Mi
```

The scheduler assumes the pod requires only 128 MiB.

---

### Limits

Maximum resources a container may consume.

Example:

```yaml
limits:
  memory: 2Gi
```

If exceeded, container-level OOM events may occur.

---

### Allocatable Resources

Resources available for workloads after reserving capacity for:

- Operating system
- kubelet
- container runtime
- system daemons

Example:

```text
Node Capacity
      -
System Reserved
      =
Allocatable
```

---

### Actual Consumption

Real runtime usage observed on the node.

The scheduler does not use this value during scheduling decisions.

---

## Memory Pressure Mechanism

Kubelet continuously monitors node health.

When available memory drops below configured thresholds:

```text
MemoryPressure=True
```

The Eviction Manager becomes active.

Typical flow:

```text
Memory Pressure
        ↓
Eviction Threshold Reached
        ↓
Pod Selection
        ↓
Pod Eviction
        ↓
Memory Reclaimed
```

The objective is protecting node stability before the Linux kernel enters a global OOM state.

---

## OOMKilled vs Evicted

### OOMKilled

Triggered by:

- Linux OOM Killer
- cgroup memory limits

Scenario:

```text
Container exceeds memory limit
        ↓
Kernel terminates process
```

Result:

```text
OOMKilled
```

---

### Evicted

Triggered by kubelet.

Scenario:

```text
Node memory becomes critically low
        ↓
Kubelet selects victims
        ↓
Pods removed from node
```

Result:

```text
Evicted
```

The node remains operational.

---

## QoS Classes

Kubernetes assigns every pod a Quality of Service class.

### BestEffort

No requests and no limits.

Highest eviction risk.

---

### Burstable

Requests exist but limits differ or are absent.

Most production workloads belong here.

---

### Guaranteed

Requests equal limits.

Highest protection during node pressure.

Example:

```yaml
requests:
  memory: 2Gi

limits:
  memory: 2Gi
```

---

## Victim Selection Logic

Eviction decisions are not based solely on QoS.

Within the same QoS class, kubelet also evaluates:

```text
Actual Usage vs Requested Resources
```

Pods consuming significantly more memory than requested become stronger eviction candidates.

Example:

```text
Request: 128Mi
Usage:   2Gi
```

Such workloads are likely targets during memory reclamation.

---

## Investigation Process

### Node Health

```bash
kubectl describe node <node>
```

Check:

```text
MemoryPressure
DiskPressure
PIDPressure
```

---

### Resource Consumption

```bash
kubectl top nodes
```

```bash
kubectl top pods -A --sort-by=memory
```

Identify memory-heavy workloads.

---

### Pod Inspection

```bash
kubectl describe pod <pod>
```

Review:

- Requests
- Limits
- Restart history
- Eviction events

---

### Cluster Events

```bash
kubectl get events --sort-by=.lastTimestamp
```

Look for:

```text
Evicted
MemoryPressure
```

---

### Kubelet Metrics

Monitor:

```text
kubelet_evictions_total
```

```text
kubelet_memory_pressure
```

```text
container_memory_working_set_bytes
```

---

## Immediate Mitigation

### Define Memory Limits

Apply realistic memory limits for all services.

Example:

```yaml
limits:
  memory: 2Gi
```

---

### Add Cluster Capacity

Increase available memory capacity by:

- Scaling node groups
- Adding additional nodes

---

### Identify Memory Hogs

Temporarily restart or isolate workloads consuming excessive memory.

---

### Redistribute Workloads

Reduce pressure on overloaded nodes while maintaining service availability.

---

## Long-Term Improvements

### Resource Right-Sizing

Adopt Vertical Pod Autoscaler recommendations.

Continuously align:

```text
Requests
Limits
Actual Usage
```

---

### Goldilocks

Use Goldilocks to analyze resource allocation efficiency.

Benefits:

- Detect overcommit
- Detect waste
- Recommend requests and limits

---

### Enforce Resource Policies

Implement:

```text
LimitRanges
ResourceQuotas
```

to prevent deployments without resource definitions.

---

### Java Memory Governance

Configure JVM parameters appropriately:

```text
-Xms
-Xmx
```

Ensure JVM memory settings remain below container limits.

---

### Capacity Planning

Maintain node headroom.

Avoid running clusters near theoretical capacity.

Reserve space for:

- Deployments
- Failovers
- Traffic spikes
- Node failures

---

## Key Lessons

The cluster was not suffering from a lack of memory.

It was suffering from inaccurate scheduling assumptions.

Kubernetes trusted declared requests, while workloads consumed significantly more resources than promised.

This mismatch created node-level memory pressure, forcing kubelet to evict pods in order to preserve cluster stability.

Accurate resource requests and limits are essential for predictable scheduling and reliable platform operations.
