# Incident Analysis — Week 11 Day 2

## Scenario

A production deployment of the checkout-api service triggered a major outage.

Environment:

- Kubernetes cluster with 120 nodes
- Deployment replicas: 60
- RollingUpdate strategy enabled
- Cluster Autoscaler enabled

During the rollout:

- one worker node became unavailable
- new Pods remained Pending
- API error rate increased to 35%
- users received HTTP 503 responses

Database, cache, and infrastructure services remained healthy.

Deployment status eventually reported:

```text
ProgressDeadlineExceeded
```

Several Pods showed:

```text
0/119 nodes are available: Insufficient CPU
```

and:

```text
volume node affinity conflict
```

Cluster Autoscaler logs showed:

```text
max node group size reached
```

---

# What Problem Happened

The outage was caused by scheduling capacity exhaustion during a rolling deployment.

The cluster had enough capacity for normal operation.

The cluster did not have enough capacity for:

- normal operation
- rolling update surge capacity
- node failure

at the same time.

The deployment entered a state where replacement Pods could not be scheduled.

As a result:

- old Pods were being replaced
- new Pods could not start
- service capacity decreased
- user requests failed

---

# Rolling Update Fundamentals

Kubernetes RollingUpdate gradually replaces old Pods with new Pods.

The goal is to avoid full service interruption.

Example configuration:

```yaml
strategy:
  rollingUpdate:
    maxUnavailable: 25%
    maxSurge: 25%
```

---

# maxUnavailable

Maximum number of Pods allowed to become unavailable during rollout.

For:

```text
replicas = 60
```

and:

```text
maxUnavailable = 25%
```

Kubernetes may temporarily lose:

```text
15 Pods
```

during deployment.

This protects service availability.

---

# maxSurge

Maximum number of extra Pods created during rollout.

For:

```text
replicas = 60
```

and:

```text
maxSurge = 25%
```

Kubernetes may temporarily create:

```text
15 additional Pods
```

above the desired replica count.

This accelerates rollout speed.

---

# Why Node Failure Was So Damaging

A worker node failed during deployment.

The node removed:

- CPU resources
- memory resources
- running Pods

from cluster capacity.

At the same time the deployment attempted to create surge Pods.

The cluster suddenly required more resources while simultaneously losing resources.

Available scheduling capacity disappeared.

---

# ProgressDeadlineExceeded

Deployment Controller monitors rollout progress.

A deployment must eventually reach:

```text
Available
Ready
```

state.

If Kubernetes cannot make progress within the configured deadline:

```text
ProgressDeadlineExceeded
```

is reported.

This means rollout is effectively stalled.

Common causes:

- Pending Pods
- failed scheduling
- failed readiness checks
- insufficient cluster capacity

---

# Why Pods Remained Pending

Pending Pods indicate that scheduling requirements cannot be satisfied.

The scheduler attempted placement but failed.

The cluster still contained running nodes.

However, none of the available nodes could satisfy all scheduling constraints.

---

# Resource Requests vs Limits

Kubernetes Scheduler uses:

```text
requests
```

not:

```text
limits
```

for placement decisions.

Example:

```yaml
resources:
  requests:
    cpu: 2
  limits:
    cpu: 8
```

Scheduler reserves:

```text
2 CPU
```

during scheduling.

Even if actual utilization is much lower.

Scheduling decisions are based on guaranteed resources.

---

# Meaning Of Insufficient CPU

This error does not mean total cluster CPU is exhausted.

It means:

```text
no individual node
has enough allocatable CPU
for the Pod request
```

A Pod may require:

```text
2 CPU
```

while each remaining node only has:

```text
1 CPU free
```

The Pod cannot be scheduled.

---

# Resource Fragmentation

Fragmentation occurs when free resources exist but are scattered.

Example:

```text
Node A = 1 CPU free
Node B = 1 CPU free
Node C = 1 CPU free
Node D = 1 CPU free
```

Total free CPU:

```text
4 CPU
```

New Pod requires:

```text
2 CPU
```

The Pod still cannot be scheduled.

Because no single node satisfies the request.

This is resource fragmentation.

---

# Volume Node Affinity Conflict

Persistent Volumes may be tied to specific infrastructure locations.

Examples:

- AWS EBS
- Azure Managed Disk
- GCP Persistent Disk

Storage may only be attachable within a particular zone.

If a Pod is rescheduled elsewhere:

```text
volume node affinity conflict
```

appears.

CPU may be available.

Memory may be available.

Storage topology prevents placement.

This is a topology-aware scheduling issue.

---

# Cluster Autoscaler Limitation

Cluster Autoscaler detected insufficient resources.

It attempted to scale the cluster.

However logs showed:

```text
max node group size reached
```

Meaning:

```text
Autoscaler was functioning correctly
but was blocked by configuration limits
```

Additional nodes could not be created.

Capacity remained exhausted.

---

# Scheduler, Capacity And Autoscaling Relationship

Scheduler places workloads.

Scheduler depends on:

- node capacity
- resource requests
- topology constraints
- affinity rules

Autoscaler only adds nodes when possible.

If autoscaler reaches configured limits:

- scheduler remains constrained
- Pending Pods accumulate
- deployments stall

Autoscaling cannot overcome hard capacity limits.

---

# Bin Packing

Bin packing attempts to maximize resource utilization.

Benefits:

- lower infrastructure cost
- higher utilization
- reduced idle capacity

Example:

```text
many Pods packed onto fewer nodes
```

---

# Risks Of Bin Packing

Highly packed clusters have little scheduling headroom.

During failures:

- resources become fragmented
- replacement Pods cannot fit
- rollouts become dangerous

Aggressive bin packing improves efficiency but reduces resilience.

---

# Immediate Mitigation

## Stop The Rollout

Prevent additional rollout activity.

Example:

```bash
kubectl rollout pause deployment/checkout-api
```

Purpose:

- stop creating new scheduling pressure

---

## Roll Back

Restore known healthy version.

Example:

```bash
kubectl rollout undo deployment/checkout-api
```

Purpose:

- remove rollout-induced capacity demand

---

## Restore Capacity

Options:

- repair failed node
- manually add worker nodes
- increase node group size limits

Purpose:

- recover scheduling headroom

---

## Reduce Replica Requirements

Temporarily lower replica count if business impact is acceptable.

Purpose:

- allow successful scheduling
- restore service availability

---

# Long-Term Improvements

## Capacity Planning

Design clusters for:

- normal operation
- rolling updates
- node failures

simultaneously.

Capacity must include failure scenarios.

---

## Increase Autoscaler Limits

Review:

```text
max node group size
```

Ensure scale-out remains possible during incidents.

---

## Improve Resource Request Accuracy

Overestimated requests increase fragmentation.

Underestimated requests increase instability.

Requests must reflect reality.

---

## Pod Disruption Budgets

Use Pod Disruption Budgets for controlled maintenance.

Purpose:

- protect availability during voluntary disruptions
- prevent excessive concurrent evictions

---

## Overprovisioning

Deploy low-priority reserve Pods.

These Pods can be preempted when real workloads require capacity.

Purpose:

- maintain scheduling headroom
- accelerate recovery

---

## Topology-Aware Architecture

Distribute workloads and storage across failure domains.

Reduce dependency on:

- individual nodes
- individual zones

Purpose:

- improve resilience
- reduce affinity-related scheduling failures

---

# Key Learning

- healthy infrastructure metrics do not guarantee schedulability
- scheduler capacity is a critical production resource
- requests drive placement decisions
- resource fragmentation causes hidden capacity loss
- rolling updates require spare capacity
- autoscalers have hard limits
- storage topology influences scheduling outcomes
- bin packing improves efficiency but reduces resilience
- clusters must be sized for failures, not only normal operation
