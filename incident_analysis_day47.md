# Incident Analysis — Week 10 Day 5

## Scenario

Traffic increased ~12x during major marketing campaign.

Architecture:

```text
Internet
   ↓
Cloud Load Balancer
   ↓
NGINX Ingress
   ↓
API Gateway
   ↓
Microservices
```

Symptoms:

- random connection timeouts
- intermittent 502/504
- latency spikes
- retries amplifying traffic
- Pods healthy but unreachable
- SYN backlog overflow
- conntrack table near exhaustion
-大量 TIME_WAIT sockets
- ephemeral port allocation failures

Kernel logs:

```text
possible SYN flooding
nf_conntrack: table full
TCP: out of memory -- consider tuning
```

Applications were healthy.

Infrastructure coordination layer was collapsing.

---

# Root Cause

The platform entered connection lifecycle meltdown.

System failure happened at:
- Linux TCP stack
- kernel networking coordination layer
- NAT state tracking
- socket lifecycle management

The incident was NOT caused by:
- application CPU
- Kubernetes orchestration
- PostgreSQL
- business logic

The infrastructure failed because the kernel could no longer coordinate enormous amounts of short-lived TCP connections.

---

# TCP Connection Lifecycle

TCP establishes connections using 3-way handshake:

```text
SYN
SYN-ACK
ACK
```

Connection then enters:

```text
ESTABLISHED
```

Termination:

```text
FIN
ACK
FIN
ACK
```

After close:
- active closer enters TIME_WAIT state

Purpose:
- prevent delayed packet corruption
- ensure old packets expire safely

TIME_WAIT may persist for tens of seconds.

At massive scale:
- millions of closed connections accumulate
- socket exhaustion begins

---

# SYN Backlog

SYN backlog stores:
- half-open TCP connections

Meaning:
- SYN received
- SYN-ACK sent
- waiting for final ACK

Connection not fully established yet.

If SYN backlog overflows:
- kernel drops new SYN packets
- clients experience timeouts
- retries increase traffic pressure

Kernel may enable:
- SYN cookies

Purpose:
- mitigate queue exhaustion

---

# Accept Queue

Accept queue differs from SYN backlog.

Accept queue stores:
- fully established connections

Handshake completed,
but application has not yet accepted socket using:

```c
accept()
```

If accept queue overflows:
- application cannot consume sockets fast enough
- kernel starts rejecting new connections

This becomes:
- application-to-kernel coordination bottleneck

---

# Conntrack Table

Kubernetes networking heavily depends on conntrack.

Conntrack is:
- stateful packet coordination system

Purpose:
- track NAT mappings
- route return packets correctly
- maintain connection state

Kubernetes uses conntrack for:
- ClusterIP
- NodePort
- kube-proxy
- SNAT/DNAT
- overlay networking

Every connection consumes conntrack entries.

At high scale:
- conntrack table becomes exhausted

Kernel then drops:
- new packets
- new connections

Result:
- random failures
- intermittent reachability
- partial outages

---

# Why Kubernetes Amplifies Networking Pressure

Each packet may traverse:

```text
veth
bridge
iptables
conntrack
overlay encapsulation
routing tables
reverse NAT
```

This creates enormous:
- coordination overhead
- packet processing overhead
- NAT amplification

Short-lived connections become extremely expensive.

---

# TIME_WAIT Explosion

TIME_WAIT protects TCP correctness.

But high connection churn causes:
- socket accumulation
- ephemeral port exhaustion
- kernel memory pressure

Important nuance:
- TIME_WAIT burden falls on active closer

If ingress aggressively closes upstream connections:
- ingress itself dies from TIME_WAIT explosion

---

# Ephemeral Port Exhaustion

Outgoing connections require temporary local ports.

Typical range:

```text
32768–60999
```

Under massive churn:
- ports consumed rapidly
- TIME_WAIT prevents immediate reuse

Eventually:

```text
connect() → EADDRNOTAVAIL
```

Meaning:
- no ports available

New outbound connections fail completely.

---

# Retry Amplification

Retries massively amplify kernel pressure.

Every retry creates:

- new SYN packets
- new sockets
- new conntrack entries
- new NAT states
- new retransmissions
- new queues
- new buffers

Retries amplify:
- coordination structures
not:
- business logic

This creates positive feedback loop.

---

# TCP Retransmissions

Packet loss triggers retransmissions.

TCP guarantees ordered delivery.

Example:

```text
50 received
51 lost
52 received
53 received
```

Application cannot process:
- 52
- 53

until:
- 51 retransmitted

This creates:
- Head-of-Line Blocking

---

# Head-of-Line Blocking

TCP enforces strict ordering.

Single lost packet stalls:
- entire stream

Under congestion:
- retransmits grow
- RTT increases
- queues expand
- tail latency explodes

This explains:
- healthy averages
- catastrophic p99 latency

---

# Why CPU Stayed Normal

Infrastructure was not compute-bound.

System failed due to:
- queue contention
- lock contention
- socket coordination
- kernel memory pressure
- softirq saturation
- networking state explosion

Processes waited on coordination structures rather than performing computations.

Applications appeared healthy while networking layer collapsed.

---

# Connection Churn

Large systems often fail because of:

```text
too many short-lived connections
```

not:
- heavy requests

Connection lifecycle coordination becomes dominant bottleneck.

This is why:
- HTTP keep-alive
- HTTP/2 multiplexing
- connection reuse
- connection pooling
are critical production optimizations.

---

# Investigation Process

## Socket Statistics

```bash
ss -s
```

Purpose:
- analyze socket states
- TIME_WAIT growth
- connection pressure

---

## SYN Queue Analysis

```bash
netstat -ant | grep SYN_RECV
```

Purpose:
- detect half-open connection accumulation

---

## Conntrack Analysis

```bash
sysctl net.netfilter.nf_conntrack_count
sysctl net.netfilter.nf_conntrack_max
```

Purpose:
- detect table exhaustion

---

## Kernel Logs

```bash
dmesg | grep conntrack
```

Purpose:
- identify kernel packet drops

---

## Packet Capture

```bash
tcpdump
```

Purpose:
- analyze retransmits
- packet loss
- SYN floods
- reset storms

---

# Production Mitigation Plan

# Short-Term Stabilization

## Increase Conntrack Limits

```bash
sysctl -w net.netfilter.nf_conntrack_max=1048576
```

Purpose:
- reduce packet drops

---

## Expand Ephemeral Port Range

```bash
sysctl -w net.ipv4.ip_local_port_range="1024 65535"
```

Purpose:
- delay port exhaustion

---

## Enable TIME_WAIT Reuse

```bash
sysctl -w net.ipv4.tcp_tw_reuse=1
```

Purpose:
- reduce socket pressure

---

## Enable SYN Cookies

```bash
sysctl -w net.ipv4.tcp_syncookies=1
```

Purpose:
- protect SYN backlog

---

## Aggressive Load Shedding

Reject excess traffic early.

Purpose:
- preserve core platform stability

---

# Long-Term Architecture

## HTTP Keep-Alive

Avoid creating new TCP connection per request.

Purpose:
- reduce connection churn

---

## Connection Pooling

Use:
- Envoy
- NGINX
- pooled upstream sockets

Purpose:
- reuse hot connections

---

## HTTP/2 Multiplexing

Multiple requests share:
- single TCP connection

Purpose:
- drastically reduce socket pressure

---

## Migrate kube-proxy to IPVS

iptables scales poorly.

IPVS uses:
- efficient hash-based routing

Purpose:
- reduce packet processing overhead

---

## Reduce NAT Amplification

Prefer:
- direct routing
- eBPF dataplanes
- Cilium

Purpose:
- reduce conntrack dependence

---

## Backpressure

System must slow traffic producers before queues collapse.

Purpose:
- prevent retry storms

---

## QUIC / HTTP3

QUIC operates over UDP.

Advantages:
- independent streams
- reduced head-of-line blocking
- better mobile performance

Loss in one stream:
- does not stall others

---

# Key Learning

Large-scale systems often fail because:
- connections become impossible to coordinate

before:
- applications become computationally overloaded

Kernel networking coordination is often the real scalability limit.
