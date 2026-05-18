# Incident Analysis — Week 9 Day 3

## Scenario

Production Kubernetes cluster experienced sudden traffic growth.

Symptoms:
- API latency increased significantly
- CPU utilization reached 90–95%
- Horizontal Pod Autoscaler attempted scaling
- replicas increased to 20
- some Pods stayed in `Pending`
- rollout slowed down
- cluster remained overloaded

Scheduler events:
- `Insufficient memory`
- `node(s) had taint`
- `didn't match node selector`

At the same time:
- some nodes remained almost empty
- other nodes became saturated

CTO concluded:
The team believes Kubernetes creates infrastructure resources from nothing.

---

## What Problem Is Happening

The cluster entered scheduling bottleneck state caused by finite infrastructure capacity and placement constraints.

The team made a fundamental mistake:
- scaling workloads
does not equal
- scaling infrastructure

Kubernetes cluster consists of finite physical or virtual nodes:
- limited CPU
- limited RAM
- limited disk
- limited scheduling space

When replicas increased:
- scheduler attempted Pod placement
- cluster resources became exhausted
- placement rules reduced available nodes further

As a result:
- new Pods could not be scheduled
- existing Pods became overloaded
- latency increased
- autoscaling stopped being effective

This created:
- scheduling congestion
- resource starvation
- degraded production performance

---

## Why Pods Stay In Pending State

`Pending` means:
- Pod object exists in etcd
- Kubernetes accepted deployment request
- but scheduler failed to assign Pod onto any node

The Pod has not started yet.

---

## Common Causes Of Pending

### Insufficient CPU Or Memory

No node has enough allocatable resources for Pod requests.

Example:
- Pod requests 4 GB RAM
- every node has only 2 GB free

Result:
- Pod remains Pending forever

---

### Node Selector / Affinity Mismatch

Pod requires specific node characteristics.

Example:
- SSD storage
- GPU hardware
- dedicated node pool

If matching nodes unavailable:
- scheduling impossible

---

### Taints Without Tolerations

Node protected by taints:
- production-only
- database-only
- GPU-only

Pod lacks required toleration:
- scheduler rejects placement

---

### Resource Fragmentation

Cluster may have enough total resources globally,
but not enough on any single node.

Example:

Node A:
- 2 CPU free
- 1 GB RAM free

Node B:
- 1 CPU free
- 4 GB RAM free

Pod requires:
- 2 CPU
- 4 GB RAM

Total resources exist,
but no single node satisfies request.

Result:
- Pod remains Pending

This is called:
- resource fragmentation

---

# Kubernetes Scheduler

Kubernetes Scheduler is cluster placement controller.

It does NOT:
- create resources
- add nodes
- increase hardware capacity

Scheduler only decides:
- where Pods should run

---

## Scheduling Pipeline

Scheduler operates in several stages.

---

## 1. Node Filtering

Scheduler evaluates all cluster nodes and removes incompatible ones.

Checks include:
- available CPU
- available memory
- taints
- affinity rules
- node selectors
- topology constraints

Nodes failing requirements are discarded immediately.

---

## 2. Node Scoring

Remaining nodes receive scores.

Scheduler attempts optimization based on:
- cluster utilization
- spreading
- balancing
- resource efficiency

---

## Bin Packing

One strategy is:
- pack workloads densely

Purpose:
- free unused nodes
- reduce cloud costs
- improve utilization

---

## Spreading

Another strategy:
- distribute workloads across nodes/zones

Purpose:
- fault isolation
- resilience
- high availability

Scheduler constantly balances:
- economics
vs
- reliability

---

## 3. Scheduling Decision

Highest-scoring node selected.

Scheduler binds Pod to node.

Then kubelet on that node:
- downloads image
- starts container
- initializes Pod

---

# Node Affinity

Node Affinity controls where Pods prefer or require placement.

Used for:
- GPU workloads
- SSD storage
- isolated hardware
- compliance requirements

---

## Affinity Types

### Preferred Affinity

Soft preference:
- scheduler tries to satisfy rule
- but may ignore it if necessary

---

### Required Affinity

Hard constraint:
- Pod cannot run without matching node

Incorrect required affinity may create Pending Pods.

---

# Pod Anti-Affinity

Anti-affinity prevents similar Pods from colocating.

Example:
- avoid placing all API replicas on same node

Purpose:
- improve fault tolerance
- avoid single-node failure impact
- spread replicas across zones

Without anti-affinity:
- one node failure may destroy entire service

---

# Taints And Tolerations

Taints protect nodes from unwanted workloads.

Node says:
- "Do not schedule Pods here"

Only Pods with matching toleration may enter.

---

## Typical Usage

- isolate databases
- separate production from staging
- dedicate GPU nodes
- protect infrastructure services

---

# Noisy Neighbor Problem

Without isolation:
- one workload may consume excessive resources
- neighboring services become unstable

This creates:
- latency spikes
- eviction pressure
- unpredictable performance

Affinity and taints help isolate workloads.

---

# Cluster Autoscaler

Scheduler cannot add hardware capacity.

Cluster Autoscaler monitors:
- Pending Pods
- unschedulable workloads

If capacity insufficient:
- autoscaler requests new nodes from cloud provider

Examples:
- AWS EC2
- Google Compute Engine
- Azure VM Scale Sets

After node joins cluster:
- scheduler retries placement

---

# Topology Spread Constraints

Production systems distribute workloads across:
- zones
- racks
- fault domains
- node groups

Purpose:
- prevent hotspot concentration
- improve resiliency
- survive node/zone failures

---

# Overprovisioning

Critical clusters often reserve spare scheduling capacity.

Technique:
- low-priority placeholder Pods consume resources

During traffic spike:
- placeholders evicted
- production Pods scheduled instantly

Purpose:
- avoid waiting for new node provisioning

---

# Production-Grade Scheduling Principles

Reliable Kubernetes scheduling requires:

---

## Explicit Resource Requests

Every critical workload must define:
- CPU requests
- memory requests
- realistic limits

Purpose:
- predictable placement
- scheduler accuracy

---

## Workload Isolation

Use:
- taints
- tolerations
- affinity rules

Purpose:
- prevent noisy neighbors
- isolate critical services

---

## High Availability Placement

Use:
- anti-affinity
- topology spread constraints

Purpose:
- survive node failures
- distribute replicas safely

---

## Infrastructure Autoscaling

Use:
- Cluster Autoscaler
- Karpenter

Purpose:
- scale infrastructure automatically
- eliminate Pending bottlenecks

---

## Balanced Resource Utilization

Avoid:
- node hotspots
- severe fragmentation
- uneven cluster saturation

Purpose:
- stable long-term operation

---

## Key Learning

- Kubernetes resources are finite
- scheduler distributes capacity but does not create it
- Pending means placement failure
- requests determine scheduling feasibility
- affinity controls placement rules
- anti-affinity improves resiliency
- taints isolate workloads
- autoscaling workloads requires autoscaling infrastructure
- production scheduling is topology engineering
