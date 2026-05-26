# Incident Analysis — Week 10 Day 4

## Scenario

Large production Kubernetes cluster experienced severe instability after major deployment activity.

Cluster profile:

```text
~700 nodes
~25,000 Pods
multi-tenant workloads
autoscaling enabled
service mesh enabled
high CI/CD activity
many custom operators
```

Symptoms:

- Pods stuck in Pending
- deployments extremely slow
- kubectl timing out
- HPA delayed
- CoreDNS instability
- intermittent NotReady nodes
- operator failures
- API requests hanging

Infrastructure itself remained mostly operational:
- worker nodes alive
- applications partially serving traffic
- networking mostly functional

Control plane metrics showed:
- API server latency increase
- exploding watch counts
- etcd fsync latency spikes
- reconciliation delays

Root cause involved:
- control plane saturation
- watch storms
- reconciliation amplification
- etcd write pressure
- API server overload
- coordination instability

rather than:
- node failure
- application crash
- network partition.

---

# Kubernetes Control Plane

Kubernetes functions as:
- distributed desired-state coordination system

Core control plane components:
- API Server
- etcd
- scheduler
- controller-manager

All cluster coordination flows through:
- control plane state synchronization.

---

# API Server

API Server is:
- central coordination gateway

Responsibilities:
- authentication
- authorization
- admission control
- object persistence
- watch distribution
- API validation

All components communicate through:
- API Server

including:
- kubelets
- scheduler
- controllers
- operators
- kubectl
- GitOps systems
- service mesh controllers

API Server therefore becomes:
# critical coordination bottleneck

in large clusters.

---

# etcd

etcd stores:
- authoritative cluster state

Examples:
- Pods
- Deployments
- Services
- Secrets
- CRDs
- Leases
- EndpointSlices

etcd is:
- distributed strongly consistent KV store

Consensus implemented through:
- Raft protocol.

All writes require:
- WAL append
- fsync
- quorum replication
- commit acknowledgement

Storage latency directly impacts:
- cluster coordination latency.

---

# Scheduler

Scheduler assigns:
- unscheduled Pods
to:
- worker nodes

Scheduling involves:
- resource fitting
- affinity rules
- anti-affinity
- taints
- tolerations
- topology constraints
- storage locality

At large scale scheduling itself becomes:
- computationally expensive.

---

# Controller Manager

Controllers continuously reconcile:
- actual cluster state
toward:
- desired state

Examples:
- Deployment controller
- ReplicaSet controller
- Node controller
- EndpointSlice controller

Kubernetes fundamentally operates through:
# reconciliation loops

rather than:
- direct imperative execution.

---

# Reconciliation Loop

Core Kubernetes model:

```text
desired state
≠
actual state
```

Controllers repeatedly:
- observe state
- compare state
- attempt convergence

This creates:
- asynchronous eventual consistency system

not:
- immediate consistency system.

Controllers rely heavily on:
- watches
- work queues
- retries
- cached state.

---

# Watch Mechanism

Kubernetes components avoid:
- aggressive polling

Instead:
- long-lived watch streams used

Components subscribe to:
- object changes

Examples:
- Pod updates
- Endpoint changes
- Lease renewals
- CRD modifications

This allows:
- near real-time coordination.

---

# Watch Storm

Massive deployment activity triggered:
- huge object churn

Each Pod lifecycle event generated:
- watch notifications
- cache invalidations
- reconciliation triggers

Thousands of watchers received:
- continuous event streams

This produced:
# watch storm

Effects:
- serialization overhead
- network fanout
- API server CPU pressure
- memory pressure
- queue amplification.

---

# Reconciliation Amplification

One object change triggered:
- many independent controllers

Examples:
- HPA
- service mesh controllers
- GitOps systems
- custom operators
- EndpointSlice controllers
- admission systems

This created:
# thundering herd problem

Flow:

```text
one Pod update
→ many watchers triggered
→ many reconcile loops start
→ many API writes generated
→ more events emitted
→ further reconciliations triggered
```

Positive feedback loop amplified:
- API pressure
- etcd writes
- coordination instability.

---

# Informer Cache

Well-designed controllers use:
- informer caches

Informer cache:
- local memory mirror of cluster state

Updated asynchronously through:
- watches

Purpose:
- reduce direct API queries
- lower API server pressure

Controllers without informers may:
- continuously query API server

creating:
# API amplification collapse

at scale.

---

# etcd fsync Latency

Every etcd write requires:
- durable WAL persistence

Critical path:

```text
write
→ WAL append
→ fsync
→ Raft replication
→ commit
```

As write volume increased:
- disk subsystem saturated

Result:
- fsync latency increased

Consequences:
- slower writes
- delayed consensus
- leader instability
- API request blocking

High etcd fsync latency is dangerous because:
- Kubernetes coordination depends on write responsiveness.

---

# Leader Election Instability

Many Kubernetes components use:
- leader election

Examples:
- controller-manager
- scheduler
- operators

Leadership coordinated through:
- Lease objects stored in etcd

When API latency increased:
- lease renewals delayed

Components falsely assumed:
- leader failure

This triggered:
- election churn
- controller instability
- coordination disruption.

---

# Why kubectl Hung

kubectl communicates through:
- API server

During saturation:
- API requests queued
- reads delayed
- watches stalled
- writes blocked by etcd latency

kubectl therefore appeared:
- frozen
- timing out

even though:
- worker nodes remained alive.

---

# CoreDNS Degradation

CoreDNS depends on:
- API watches

CoreDNS watches:
- Services
- EndpointSlices
- Pod networking data

When API propagation delayed:
- DNS state became stale

Consequences:
- failed service discovery
- intermittent DNS resolution
- stale endpoint routing

This created:
- apparent network instability

despite:
- underlying network mostly healthy.

---

# Service Mesh Amplification

Service mesh sidecars dramatically increased:
- control plane pressure

Each injected sidecar required:
- additional config
- certificates
- xDS updates
- endpoint awareness
- policy synchronization

Admission webhooks added:
- synchronous API dependencies

Pod creation path became:

```text
Pod request
→ admission webhook
→ mutation
→ API persistence
```

At large scale:
- sidecar injection amplified API load multiplicatively.

---

# Admission Webhooks

Admission webhooks execute:
- synchronous request interception

Danger:
- webhook latency blocks API requests

If webhook overloaded:
- Pod creation stalls
- deployments freeze
- API latency cascades

Webhooks become:
# hidden critical dependencies

inside control plane.

---

# CRD Explosion

Custom Resource Definitions expand:
- Kubernetes API surface

Each CRD introduces:
- new objects
- new watches
- new caches
- new reconciliation loops

Poorly designed operators can generate:
- excessive reconciliation traffic
- API storms
- etcd object bloat

Large CRD ecosystems therefore increase:
- coordination complexity
- control plane pressure.

---

# Event Storms

Kubernetes Events generate:
- additional writes into etcd

Large-scale failures may create:
- massive event churn

Events themselves can:
- amplify storage pressure
- increase API latency.

---

# Autoscaling Destabilization

Aggressive autoscaling dangerous because:
- scaling creates object churn

Each scaling event triggers:
- Pod creation
- scheduling
- endpoint updates
- mesh updates
- DNS updates
- reconciliation loops

At scale:
- autoscaling itself may destabilize control plane.

---

# Kubelet Amplification

Each kubelet continuously reports:
- node heartbeats
- PodStatus updates
- resource metrics

At 700 nodes:
- kubelet traffic alone becomes significant

Under instability:
- retries amplify load further.

---

# API Priority and Fairness (APF)

API Priority and Fairness protects:
- critical control plane traffic

Allows:
- request isolation
- fairness queues
- concurrency shares

Prevents:
- noisy controllers starving critical systems.

Without APF:
- low-priority systems may exhaust API capacity.

---

# Eventual Consistency Inside Kubernetes

Kubernetes internally operates under:
- eventual consistency

Controllers observe:
- delayed cached state

Implications:
- temporary inconsistencies normal
- stale reads expected
- races unavoidable

Large clusters amplify:
- coordination lag.

---

# Control Plane Backpressure

Healthy clusters require:
- bounded reconciliation
- bounded retries
- bounded watches
- bounded event fanout

Without backpressure:
- positive feedback loops emerge

Result:
# distributed coordination collapse

rather than:
- immediate infrastructure crash.

---

# Investigation Process

## API Server Metrics

Inspect:
- request latency
- inflight requests
- request queue depth
- slow endpoints

Critical metrics:
- apiserver_request_duration_seconds
- apiserver_current_inflight_requests

---

# etcd Health

Inspect:
- WAL fsync latency
- Raft commit latency
- leader stability
- backend database size

Critical metrics:
- etcd_disk_wal_fsync_duration_seconds
- etcd_server_leader_changes_seen_total

---

# Watch Counts

Analyze:
- watcher counts
- high-frequency clients
- noisy controllers

Identify:
- watch amplification sources.

---

# Controller Queues

Inspect:
- reconciliation queue depth
- retry rates
- processing latency

Detect:
- reconciliation backlog.

---

# Scheduler Latency

Measure:
- scheduling duration
- pending Pod growth
- scheduling retries

Purpose:
- detect scheduling saturation.

---

# Admission Webhook Analysis

Inspect:
- webhook latency
- timeout rates
- mutation overhead

Detect:
- synchronous admission bottlenecks.

---

# Production Mitigation Plan

## Short-Term Stabilization

- freeze deployments
- disable aggressive autoscaling
- pause GitOps reconciliation
- reduce controller concurrency
- restart unstable operators
- limit watch-heavy systems
- enable API Priority and Fairness
- reduce sidecar injection scope

Goal:
- stop amplification loops.

---

# etcd Emergency Stabilization

- isolate etcd onto dedicated NVMe storage
- reduce write amplification
- compact stale objects
- remove unnecessary CRDs
- reduce event retention

Goal:
- restore low fsync latency.

---

# Long-Term Improvements

## Informer-Only Controllers

Require:
- informer cache usage

Ban:
- aggressive API polling.

---

# Cluster Sharding

Large clusters increase:
- blast radius
- coordination pressure
- watch fanout

Preferred strategy:
- multiple smaller clusters

instead of:
- one massive cluster.

---

# Operator Governance

Audit:
- reconciliation frequency
- API behavior
- retry logic
- watch usage

Prevent:
- poorly designed operators from overwhelming cluster.

---

# Service Mesh Optimization

Reduce:
- global config fanout
- sidecar scope
- unnecessary watches

Limit:
- mesh visibility domains.

---

# Architectural Lessons

Large Kubernetes clusters fail not because:
- containers crash

but because:
- control plane can no longer coordinate desired state

Critical failure modes emerge from:
- watch storms
- reconciliation amplification
- etcd write pressure
- admission bottlenecks
- event fanout
- autoscaling churn
- control loop instability

Kubernetes is fundamentally:
- distributed coordination system

and coordination scalability defines:
- cluster reliability.

---

# Key Learning

- Kubernetes control plane is distributed coordination infrastructure
- API server becomes bottleneck under large-scale event churn
- etcd storage latency directly impacts cluster stability
- watch storms amplify reconciliation pressure
- service mesh and CRDs multiply control plane load
- eventual consistency creates coordination lag
- poorly designed controllers can destabilize entire clusters
- large clusters require strict control plane governance
