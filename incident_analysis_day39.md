# Incident Analysis — Week 9 Day 4

## Scenario

Production PostgreSQL was migrated into Kubernetes.

Team deployed database using:

```yaml
kind: Deployment
replicas: 3
```

After several days production entered unstable state.

Symptoms:
- inconsistent data
- old reads
- conflicting table versions
- replication instability
- split-brain behavior
- storage attached to wrong node
- PVC stuck in Pending
- database recovery became slow after node failures

CTO conclusion:
The team attempted to scale PostgreSQL like a stateless web service.

---

# What Problem Is Happening

The core architectural failure is treating stateful infrastructure as stateless workload.

Team applied:
- cattle model
to
- persistent database system

This violates distributed state consistency principles.

Stateless services:
- disposable
- interchangeable
- horizontally replicated
- identity-independent

Databases are fundamentally different.

A database node:
- owns persistent state
- maintains history
- depends on replication ordering
- requires stable identity
- participates in distributed consensus

Using Deployment for PostgreSQL created:
- uncontrolled replicas
- unstable identities
- inconsistent storage ownership
- invalid replication topology

Result:
- multiple nodes attempted leadership
- replication diverged
- storage consistency collapsed

This produced split-brain behavior.

---

# Stateless vs Stateful Workloads

Stateful systems differ from stateless systems in several critical dimensions.

---

# 1. Identity

Stateless Pods are anonymous.

Example:

```text
api-7c4b9b-abc12
```

If Pod dies:
- replacement Pod receives new identity
- traffic continues normally

Stateful systems require deterministic identity.

Example:

```text
db-0
db-1
db-2
```

Identity defines:
- replication role
- cluster topology
- synchronization behavior

Stable identity is mandatory.

---

# 2. Ordering

Stateless workloads may:
- start simultaneously
- terminate simultaneously
- scale arbitrarily

Stateful systems require strict ordering.

Example:
- primary database must initialize first
- replicas start afterward
- replication established sequentially

Incorrect startup order may:
- corrupt replication
- break cluster bootstrap
- produce inconsistent state

---

# 3. Persistence

Stateless data is temporary.

Pod deletion destroys:
- cache
- local filesystem
- temporary state

Stateful data must survive:
- Pod restarts
- node failures
- rescheduling
- rolling updates

Persistent state must outlive compute lifecycle.

---

# 4. Stable Networking

Databases require deterministic addressing.

Replication topology depends on:
- stable DNS names
- fixed node identity
- predictable endpoints

Traditional Kubernetes Service load balancing is unsuitable for replication traffic.

Database replicas must know:
- exact primary endpoint
- exact replica identities

---

# StatefulSet

StatefulSet is Kubernetes controller for stateful workloads.

Unlike Deployment, StatefulSet guarantees:
- stable Pod identity
- ordered startup
- ordered shutdown
- stable storage association

Pods receive deterministic names:

```text
db-0
db-1
db-2
```

If Pod recreated:
- identity preserved
- associated storage reattached

This enables:
- replication stability
- deterministic failover
- consistent topology

---

# Headless Service

Headless Service configured with:

```yaml
clusterIP: None
```

Unlike normal Service:
- no virtual IP created
- no traffic load balancing performed

Instead:
- DNS resolves directly to Pod IPs

Example:

```text
db-0.postgres.svc.cluster.local
```

Purpose:
- direct Pod discovery
- stable replication addressing
- topology visibility

Headless Service exposes Pod identity rather than hiding it.

---

# PersistentVolume (PV)

PersistentVolume represents actual storage resource.

Examples:
- cloud block storage
- SAN storage
- Ceph volume
- NVMe device

PV exists independently from Pods.

Purpose:
- persistent infrastructure storage

---

# PersistentVolumeClaim (PVC)

PVC is storage request abstraction.

Pod requests storage through PVC.

StatefulSet creates deterministic PVC mapping:

```text
data-db-0
data-db-1
```

If Pod recreated:
- same PVC reused
- same data restored

PVC provides:
- persistent ownership
- storage continuity
- durable state lifecycle

---

# Why Storage Is The Hardest Kubernetes Layer

Storage introduces physical constraints absent in stateless compute systems.

---

# Attach / Detach Complexity

Storage volumes physically attached to nodes.

After node failure:
- volume detached from dead node
- reattached to new node
- filesystem remounted
- database recovery started

This process may require minutes.

During transition:
- Pod remains Pending
- database unavailable

Storage mobility slower than compute mobility.

---

# Node Locality

Some storage tied to specific zones or nodes.

Scheduler cannot freely move database Pods everywhere.

Placement constrained by:
- storage topology
- zone affinity
- hardware locality

This creates scheduling complexity.

---

# ReadWriteOnce vs ReadWriteMany

Most performant block storage supports:

```text
ReadWriteOnce (RWO)
```

Meaning:
- only one node may mount volume simultaneously

Attempting multiple writers risks corruption.

Shared storage modes:

```text
ReadWriteMany (RWX)
```

allow multi-node access,
but often introduce:
- higher latency
- lower performance
- consistency tradeoffs

---

# Data Gravity

Large datasets difficult to relocate.

Terabytes of database state cannot move instantly across cluster.

Applications must move toward data.

Not vice versa.

This principle called:
- data gravity

---

# Split Brain

Split brain occurs when multiple database nodes believe they are primary leaders simultaneously.

Result:
- conflicting writes
- divergent histories
- broken replication
- unrecoverable consistency problems

Split brain often worse than temporary downtime.

Preventing split brain is critical.

---

# Kubernetes Does NOT Solve Consensus

Kubernetes orchestrates:
- containers
- Pods
- scheduling
- lifecycle

Kubernetes does NOT automatically solve:
- leader election
- write quorum
- replication consistency
- distributed consensus

Consensus requires additional systems:
- Patroni
- Etcd
- Raft
- distributed coordination layers

---

# Production-Grade Stateful Architecture

Reliable database infrastructure requires specialized architecture.

---

# StatefulSet Instead Of Deployment

Databases must use:
- StatefulSet
not
- Deployment

Purpose:
- stable identity
- deterministic storage
- ordered lifecycle

---

# Dedicated Persistent Storage

Use:
- durable block storage
- isolated storage classes
- dedicated database disks

Avoid:
- ephemeral local container storage

---

# Consensus Layer

Use distributed coordination systems:
- Patroni
- Etcd
- Raft-based orchestration

Purpose:
- leader election
- failover safety
- split-brain prevention

---

# Operator Pattern

Production Kubernetes databases usually managed by Operators.

Examples:
- CloudNativePG
- Zalando Postgres Operator

Operator acts as:
- domain-specific automation controller

Operator handles:
- failover
- backups
- replication
- upgrades
- recovery
- topology management

---

# Dedicated Database Nodes

Database workloads isolated from stateless applications.

Use:
- taints
- tolerations
- node affinity

Purpose:
- prevent noisy neighbors
- isolate IO-intensive workloads
- stabilize latency

---

# Production Storage Principles

Reliable stateful infrastructure requires:

- stable identity
- persistent storage
- deterministic networking
- ordered startup
- consensus management
- replication coordination
- split-brain prevention
- storage topology awareness
- dedicated infrastructure
- operator-based lifecycle automation

---

# Key Learning

- stateless replication differs fundamentally from stateful replication
- databases require identity and persistence
- StatefulSet preserves stable topology
- storage lifecycle independent from Pod lifecycle
- Kubernetes orchestration does not equal distributed consensus
- split brain is catastrophic
- storage mobility constrained by physics
- data gravity shapes infrastructure architecture
- production databases require dedicated operational patterns
