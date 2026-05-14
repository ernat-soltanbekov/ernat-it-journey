# Incident Analysis — Week 8 Day 6

## Scenario

Team successfully deployed API into Kubernetes.

Pods were running.
ReplicaSets maintained replica count.
Deployments updated successfully.

However, new problems appeared:
- frontend intermittently received 502 Bad Gateway
- some requests reached old API versions
- internal services worked, but external API became unreachable
- connections broke after Pod restart
- developers tried using direct Pod IPs
- NodePorts were manually opened for multiple services

CTO concluded that the team does not understand Kubernetes networking model.

---

## What Problem Is Happening

The team incorrectly treats Pod IP addresses as stable infrastructure endpoints.

This contradicts Kubernetes architecture:
- Pods are ephemeral
- Pod IPs are temporary
- Pods are continuously replaced during scaling, deployment, and recovery

As a result:
- connections break after Pod recreation
- traffic routing becomes unstable
- infrastructure becomes tightly coupled to runtime state

Additionally:
- uncontrolled NodePort exposure creates operational and security chaos

---

## What Kubernetes Service Actually Is

Service is a stable virtual networking abstraction over a dynamic group of Pods.

Mechanically, Service works through:
- virtual IP allocation
- label selectors
- endpoint tracking
- kube-proxy traffic routing

Service does not track Pods directly.

Instead:
1. Service selects Pods using labels
2. Kubernetes continuously updates Endpoints list
3. kube-proxy configures networking rules
4. traffic is routed toward healthy Pods

Traffic forwarding is usually implemented using:
- iptables
- IPVS

on every cluster node.

---

## Why Service Solves Ephemeral Pod IP Problem

Pods can:
- crash
- restart
- reschedule
- scale
- update

Every recreated Pod receives a new IP address.

Service solves this by providing:
- stable virtual IP
- stable DNS name
- automatic backend discovery

Applications communicate with:
- Service

instead of:
- direct Pod addresses

When Pods change:
- Endpoints update automatically
- Service IP remains unchanged

Result:
- clients remain unaffected by Pod lifecycle events

---

## ClusterIP

ClusterIP is the default Service type.

Characteristics:
- internal cluster access only
- inaccessible from the internet
- used for internal communication

Typical usage:
- PostgreSQL
- Redis
- internal APIs
- backend communication

ClusterIP improves:
- security
- isolation
- internal service discovery

---

## NodePort

NodePort exposes Service through a static port on every cluster node.

Mechanism:
- Kubernetes opens port range (usually 30000–32767)
- traffic reaching node:port redirects into Service

Characteristics:
- externally reachable
- simple but limited
- often used for testing or small systems

Problems:
- poor scalability
- difficult port management
- increased attack surface

NodePort should not become primary production exposure strategy.

---

## LoadBalancer

LoadBalancer integrates Kubernetes with cloud provider infrastructure.

Mechanism:
- Kubernetes requests external cloud load balancer
- cloud provider allocates public IP
- traffic forwards into cluster Services

Characteristics:
- production-grade external exposure
- managed traffic distribution
- cloud-native integration

Typically used in:
- AWS
- GCP
- Azure

LoadBalancer often works together with NodePort internally.

---

## What Ingress Is

Ingress is Layer 7 HTTP/HTTPS routing abstraction.

Ingress does not directly forward packets.

Instead, it defines routing rules:
- host-based routing
- path-based routing
- TLS termination
- redirects
- traffic policies

Example:
- mysite.kz/api → API service
- mysite.kz/admin → admin service

Ingress allows:
- one public entrypoint
- centralized SSL handling
- smart HTTP routing

---

## Ingress Controller

Ingress resource alone does nothing.

Actual traffic processing is performed by:
- Ingress Controller

Examples:
- NGINX Ingress
- Traefik
- HAProxy
- Kong

Ingress Controller reads Kubernetes Ingress objects and configures reverse proxy behavior.

---

## Layer 4 vs Layer 7

LoadBalancer primarily operates at:
- Layer 4 (TCP/UDP)

Ingress operates at:
- Layer 7 (HTTP/HTTPS)

Difference:
- Layer 4 routes packets
- Layer 7 understands HTTP requests

Ingress can route based on:
- URL paths
- domains
- headers
- TLS configuration

---

## Key Learning

- Pod IPs are temporary
- Services provide stable networking abstraction
- kube-proxy routes traffic toward healthy Pods
- ClusterIP is internal-only
- NodePort exposes node-level ports
- LoadBalancer integrates cloud external networking
- Ingress provides Layer 7 HTTP routing
- Kubernetes networking depends on abstractions, not direct infrastructure addresses
