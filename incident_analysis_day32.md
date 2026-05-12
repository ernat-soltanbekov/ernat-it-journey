# Incident Analysis — Week 8 Day 4

## Scenario

Team deployed API containers using Docker on a single server.

After several weeks:
- containers occasionally crashed at night
- API stayed offline after container failure
- one container could not handle production load
- deployments caused downtime
- developers manually restarted services
- configuration drift appeared between servers

CTO concluded that Docker solved packaging problems but not infrastructure management.

---

## What Problem Is Happening

The system lacks automated lifecycle management.

Docker guarantees:
- reproducible runtime environment
- container isolation
- consistent packaging

But Docker alone does not manage:
- cluster state
- failover
- automatic recovery
- scaling
- deployment coordination

The infrastructure depends on manual operational actions.

Result:
- fragile production environment
- operational overhead
- downtime risk
- inconsistent infrastructure state

---

## Why Docker Alone Is Not Enough For Production

Docker is a container runtime, not a distributed orchestration system.

Docker Engine only understands:
- local containers
- local resources
- local runtime state

It does not understand:
- cluster-wide health
- infrastructure topology
- distributed scheduling
- automatic failover

Problems:
- no high availability
- no self-healing
- manual scaling
- downtime during deployments
- manual infrastructure recovery

---

## What Orchestration Is

Container orchestration is automated infrastructure state management.

Orchestrator continuously compares:

### Desired State

Example:
- 5 healthy API replicas must exist

---

### Current State

Example:
- only 4 replicas are currently running

---

### Reconciliation Action

Orchestrator automatically:
- creates missing containers
- reschedules workloads
- restores desired infrastructure state

This mechanism is called:
- reconciliation loop

The goal is continuous convergence toward desired system state.

---

## What Problems Orchestrators Solve

### 1. Self-Healing

If container crashes:
- orchestrator recreates it automatically

If node fails:
- workloads move to healthy nodes

---

### 2. Scaling

Infrastructure automatically adjusts:
- replica count
- resource allocation

based on:
- CPU load
- memory usage
- traffic volume

---

### 3. Rolling Updates

Containers update gradually:
- one replica at a time

Traffic continues flowing during deployment.

Result:
- zero or minimal downtime

---

### 4. Service Discovery

Services communicate through stable internal names instead of dynamic IP addresses.

---

### 5. Load Balancing

Traffic distributes automatically across healthy replicas.

---

### 6. Scheduling

Orchestrator decides:
- on which node workloads should run

based on:
- available CPU
- RAM
- node health
- resource constraints
- infrastructure policies

---

## Why Kubernetes Appeared

At large scale manual infrastructure management becomes impossible.

Google originally solved this problem internally using:
- Borg

Kubernetes inherited many Borg concepts.

Main reasons Kubernetes appeared:
- container management at massive scale
- cluster abstraction
- automated infrastructure operations
- declarative deployment management

---

## Declarative Infrastructure Concept

Traditional approach:

Administrator manually performs operations.

Example:
- start container here
- restart service there

---

Kubernetes approach:

Engineer declares desired system state.

Example:
- system must always maintain 5 healthy replicas

Kubernetes continuously works to enforce that state automatically.

---

## Control Plane vs Worker Nodes

### Control Plane

Cluster brain responsible for:
- API management
- scheduling
- orchestration decisions
- cluster state management

---

### Worker Nodes

Machines responsible for:
- running containers
- executing workloads
- serving application traffic

---

## Key Learning

- Docker solves packaging and runtime consistency
- Production systems require orchestration
- Orchestrators manage desired infrastructure state
- Kubernetes automates recovery, scaling, and deployments
- Modern infrastructure is declarative rather than manually operated
