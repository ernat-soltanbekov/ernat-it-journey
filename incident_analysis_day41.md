# Incident Analysis — Week 9 Day 6

## Scenario

Production Kubernetes cluster experienced intermittent service failures.

Symptoms:
- some requests succeeded
- some requests timed out
- some Pods reachable
- some Pods unreachable

Observed behavior:

```text
curl service-name
→ sometimes works
→ sometimes hangs
→ sometimes timeouts
```

Cluster observations:
- Pods Running
- readiness probes healthy
- CPU normal
- memory normal
- ingress healthy
- database healthy
- application logs clean

Additional observation:

```text
kubectl get endpoints
```

sometimes showed:
- full endpoint list

and sometimes:
- missing endpoints

Redeploy temporarily fixed issue for approximately:
- 15–20 minutes

---

# Kubernetes Service Architecture

Kubernetes Service provides stable virtual access layer for Pods.

ClusterIP is:
- virtual IP abstraction
- not physical interface address

Traffic sent to ClusterIP intercepted by:
- kube-proxy
- Linux networking stack

Traffic forwarding implemented through:
- iptables
or:
- IPVS

Service routing uses:
- destination NAT (DNAT)

Packets redirected from:
- virtual Service IP

to:
- actual Pod IP.

---

# kube-proxy

kube-proxy responsible for translating Kubernetes Service state into Linux packet forwarding rules.

kube-proxy continuously watches:
- API Server
- Services
- EndpointSlices

When endpoints change:
- kube-proxy regenerates forwarding rules.

kube-proxy acts as bridge between:
- Kubernetes control plane
and:
- Linux networking data plane.

---

# Endpoints and Service Discovery

Service discovers Pods through:
- label selectors

Matching Pods automatically added into:
- EndpointSlice objects

Endpoints define:
- actual traffic destinations

Without valid endpoints:
- Service has nowhere to route traffic.

Endpoint propagation chain:

```text
Pod state changes
→ EndpointSlice update
→ API Server update
→ kube-proxy watch event
→ iptables/IPVS update
→ packet forwarding changes
```

Any propagation failure creates:
- stale routing state
- inconsistent forwarding behavior.

---

# Control Plane vs Data Plane

Kubernetes control plane defines:
- desired cluster state.

Examples:
- API Server
- etcd
- controllers

Data plane performs:
- actual packet forwarding.

Examples:
- kube-proxy
- iptables
- IPVS
- Linux kernel networking
- CNI routing

Critical production insight:

```text
control plane may appear healthy
while packet forwarding remains broken
```

Healthy Kubernetes objects do not guarantee healthy traffic flow.

---

# Why Failures Were Intermittent

Problem behavior strongly indicates:
- partial forwarding inconsistency

rather than:
- total infrastructure outage.

Most likely failure pattern:
- kube-proxy desynchronization
combined with:
- conntrack pressure
or:
- stale iptables state.

Result:
- some nodes routed correctly
- some nodes routed stale endpoints
- some packets dropped
- failures became probabilistic

This explains:
- partial success rates
- random timeouts
- inconsistent service reachability.

---

# kube-proxy Desynchronization

kube-proxy depends on continuous synchronization with API Server.

Potential failures include:
- delayed watch events
- failed reconciliation loops
- incomplete iptables regeneration
- stale EndpointSlice state

Different nodes may therefore maintain:
- different forwarding tables

Example:

```text
Node A → routes correctly
Node B → stale endpoint
Node C → missing endpoint
```

This creates distributed routing inconsistency across cluster.

---

# Conntrack Table Exhaustion

Linux conntrack subsystem tracks:
- TCP states
- NAT mappings
- connection lifecycle

Kubernetes networking heavily depends on conntrack because:
- DNAT
- Service routing
- overlay networking
- kube-proxy packet rewriting

If conntrack table exhausted:
- kernel drops new connections
- existing flows may continue
- failures become intermittent

This commonly produces:
- random timeouts
- partial connectivity
- probabilistic request success

Key metrics:

```bash
sysctl net.netfilter.nf_conntrack_count
sysctl net.netfilter.nf_conntrack_max
```

---

# iptables Drift

Large Kubernetes clusters may accumulate:
- massive iptables rule sets

Rule reconciliation may become:
- delayed
- inconsistent
- partially applied

Possible outcomes:
- stale routing entries
- outdated endpoint mappings
- missing DNAT rules

This phenomenon known as:
- iptables drift

Different nodes may therefore contain:
- different packet forwarding state.

---

# CNI Layer

Container Network Interface (CNI) provides:
- Pod networking
- overlay routing
- Pod-to-Pod communication

Examples:
- Calico
- Flannel
- Cilium

CNI failures may produce:
- broken Pod routes
- overlay instability
- missing network paths
- ARP/neighbor inconsistencies

Important investigation commands:

```bash
ip route
ip neigh
```

---

# DNS Propagation Considerations

DNS caching may amplify intermittent failures.

Potential issues:
- stale DNS cache
- outdated endpoint records
- delayed CoreDNS propagation

Clients may continue sending traffic toward:
- terminated Pods

However in this incident:
- endpoint inconsistency
- kube-proxy behavior
- temporary redeploy recovery

more strongly suggest:
- forwarding-state desynchronization

than:
- pure DNS issue.

---

# Why Redeploy Temporarily Fixed Issue

Redeploy triggered:
- Pod recreation
- EndpointSlice refresh
- connection reset
- kube-proxy reconciliation

Temporary effects:
- stale state cleared
- forwarding tables refreshed
- conntrack entries partially reset

However underlying synchronization issue remained unresolved.

Therefore failures eventually returned.

---

# Investigation Process

## Kubernetes State

Check:
- Services
- EndpointSlices
- kube-proxy health

Commands:

```bash
kubectl get svc
kubectl get endpoints
kubectl get endpointslices
kubectl logs -n kube-system kube-proxy
```

---

# Node Networking

Compare forwarding state between:
- healthy nodes
- failing nodes

Commands:

```bash
iptables-save
ipvsadm -Ln
ip route
ip neigh
```

---

# Conntrack Analysis

Inspect conntrack pressure:

```bash
sysctl net.netfilter.nf_conntrack_count
sysctl net.netfilter.nf_conntrack_max
```

---

# Packet Tracing

Validate packet flow:

```bash
tcpdump -i any host <pod-ip>
```

Purpose:
- determine whether packets reach destination Pods.

---

# Production Mitigation Plan

## Short-Term Mitigation

- restart kube-proxy
- refresh forwarding rules
- increase conntrack limits
- clear stale networking state
- isolate failing nodes

---

# Long-Term Prevention

## Migrate Toward IPVS

IPVS scales better than:
- large iptables rule chains

Benefits:
- faster reconciliation
- more efficient load balancing
- improved scalability

---

# Improve Observability

Monitor:
- conntrack utilization
- kube-proxy sync latency
- EndpointSlice propagation delay
- packet drops
- DNS latency

---

# Harden Networking Layer

Perform:
- CNI audits
- route validation
- kube-proxy health monitoring
- forwarding consistency checks

---

# Architectural Lessons

Reliable Kubernetes networking depends on:
- synchronization consistency
- endpoint propagation correctness
- Linux kernel networking health
- kube-proxy reconciliation stability

Kubernetes object health alone does not prove:
- functional packet delivery.

---

# Key Learning

- Kubernetes Services are virtual forwarding abstractions
- healthy Pods do not guarantee healthy networking
- control plane and data plane may diverge
- kube-proxy synchronization failures create probabilistic outages
- conntrack exhaustion causes intermittent packet drops
- redeploy may temporarily mask infrastructure problems
- distributed systems frequently fail partially rather than completely
