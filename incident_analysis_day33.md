# Incident Analysis — Week 8 Day 5

## Scenario

Team migrated services into Kubernetes.

After deployment:
- containers constantly restarted
- Pod IP addresses changed
- services occasionally lost backend connectivity
- some requests reached old API versions after updates
- developers manually created containers using kubectl run
- scaling behavior became inconsistent

CTO concluded that the team does not understand core Kubernetes abstractions.

---

## What Problem Is Happening

The team applies Docker-oriented infrastructure thinking inside Kubernetes.

They treat:
- containers as permanent servers
- Pod IP addresses as stable endpoints
- manual runtime operations as normal workflow

This contradicts Kubernetes architecture principles:
- infrastructure is ephemeral
- workloads are declarative
- runtime state is continuously reconciled

Result:
- unstable deployments
- inconsistent scaling
- networking failures
- operational chaos

---

## What Pod Actually Is

Pod is the smallest deployable and schedulable unit in Kubernetes.

A Pod is not simply a container.

Mechanically, Pod is a shared runtime environment containing:
- shared network namespace
- shared localhost
- shared storage volumes
- shared lifecycle boundaries

All containers inside a Pod:
- share one IP address
- communicate through localhost
- can mount the same volumes

Example:
- API container
- logging sidecar
- monitoring agent

can work together inside one Pod.

---

## Why Kubernetes Manages Pods Instead Of Containers

Kubernetes orchestrates tightly coupled workloads as a single atomic unit.

If Kubernetes managed containers independently:
- related processes could be scheduled onto different nodes
- shared localhost communication would break
- sidecar architecture would become unreliable

Pod guarantees:
- co-location
- shared networking
- shared lifecycle
- deployment consistency

Kubernetes schedules, replaces, and scales entire Pods.

---

## What ReplicaSet Is

ReplicaSet is a controller responsible for maintaining desired Pod count.

Example:
- desired replicas = 5

If one Pod crashes:
- ReplicaSet automatically creates replacement Pod

Main responsibility:
- desired replica reconciliation

ReplicaSet enables:
- self-healing
- high availability
- replica consistency

---

## What Deployment Is

Deployment is a higher-level controller managing ReplicaSets.

Deployment responsibilities:
- rolling updates
- rollout management
- rollback support
- version transitions

During update:
1. new ReplicaSet is created
2. new Pods gradually start
3. old Pods gradually terminate

Result:
- zero or minimal downtime deployment

---

## Why Pod IP Addresses Are Temporary

Pods are ephemeral infrastructure objects.

Pods can be:
- recreated
- rescheduled
- replaced
- evicted

When Pod is recreated:
- new IP address is assigned

Therefore:
- Pod IPs must never be treated as stable infrastructure endpoints

Direct Pod IP dependency creates fragile systems.

---

## What Kubernetes Service Solves

Service provides stable virtual networking abstraction.

Service:
- exposes stable virtual IP/DNS name
- automatically routes traffic
- hides Pod replacement and IP changes

Applications communicate through:
- Services

not through:
- direct Pod addresses

This decouples networking from Pod lifecycle.

---

## Immutable Infrastructure Principle

Kubernetes typically does not repair broken Pods.

Instead:
1. unhealthy Pod is terminated
2. replacement Pod is created

This model is called:
- immutable infrastructure
- repair through replacement

Infrastructure becomes:
- predictable
- reproducible
- self-healing

---

## Key Learning

- Pod is the core Kubernetes runtime abstraction
- Containers inside Pod share runtime environment
- ReplicaSet maintains desired replica count
- Deployment manages rollout lifecycle
- Pod IPs are temporary
- Services provide stable networking abstraction
- Kubernetes infrastructure is declarative and ephemeral
