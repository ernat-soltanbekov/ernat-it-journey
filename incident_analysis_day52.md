# Incident Analysis — Week 11 Day 3

## Scenario

A Kubernetes platform running Istio Service Mesh experienced a major production outage.

Environment:

- Kubernetes
- Istio
- Envoy Sidecars
- STRICT mTLS
- PostgreSQL
- Kafka
- 350+ microservices

The platform had been stable for several months.

Twenty-four hours after a certificate rotation operation performed by the security team, services began failing with:

- HTTP 500
- HTTP 503
- upstream connect errors
- TLS handshake failures
- certificate validation failures
- peer certificate expired

Infrastructure dashboards appeared healthy:

- CPU normal
- Memory normal
- Network normal
- PostgreSQL healthy
- Kafka healthy

Restarting some Pods temporarily restored communication, while other services continued failing.

---

# Root Cause

The most probable root cause was an incomplete certificate rotation within the Service Mesh.

Istiod began issuing new workload certificates and trust bundles after certificate rotation.

Some Envoy sidecars successfully received updated secrets through SDS.

Other sidecars continued operating with outdated certificates or outdated trust bundles.

As certificate expiration deadlines were reached, mutual TLS validation started failing between workloads.

Because the mesh operated in STRICT mTLS mode, any certificate validation failure immediately prevented service-to-service communication.

The result was a large-scale communication outage despite healthy application infrastructure.

---

# How mTLS Works Inside Service Mesh

Mutual TLS requires both communication participants to authenticate themselves.

Unlike standard TLS:

- client presents certificate
- server presents certificate

Both sides verify:

- certificate validity
- certificate chain
- certificate expiration
- trusted root authority

Only after successful validation can encrypted communication begin.

This provides:

- encryption
- authentication
- workload identity verification

---

# Role Of Envoy Sidecars

Applications do not directly perform TLS operations.

Each Pod contains an Envoy sidecar.

Envoy intercepts:

- inbound traffic
- outbound traffic

Responsibilities include:

- mTLS encryption
- certificate validation
- traffic policies
- retries
- routing
- observability

Applications continue communicating using normal HTTP or gRPC.

Envoy transparently secures communication.

---

# Certificate Distribution

Certificates are distributed through:

```text
SDS
Secret Discovery Service
```

Workflow:

1. Envoy starts.
2. Envoy connects to Istiod.
3. Istiod provides:
   - workload certificate
   - private key
   - trust bundle
4. Envoy continuously watches for updates.

When rotation occurs, Envoy should receive updated secrets without Pod restart.

---

# Meaning Of "Peer Certificate Expired"

The message:

```text
peer certificate expired
```

means the remote workload presented a certificate that is no longer valid.

Certificate validation failed because:

- expiration time passed
- trust bundle mismatch occurred
- certificate chain could not be validated

TLS handshake terminates immediately.

Connection establishment fails.

---

# Why The Problem Appears Gradually

Not all Pods receive updates simultaneously.

Possible reasons:

- stale SDS connections
- delayed xDS propagation
- disconnected proxies
- outdated trust bundles
- control plane synchronization issues

Therefore:

- some services communicate successfully
- some services partially fail
- some services completely fail

The outage spreads gradually as certificates expire.

---

# Istio Components Involved

## Istiod

Responsibilities:

- certificate authority functions
- workload certificate issuance
- trust bundle distribution
- SDS service
- xDS configuration distribution

---

## Envoy

Responsibilities:

- certificate consumption
- certificate validation
- mTLS communication

---

## SDS

Responsibilities:

- dynamic secret delivery
- secret rotation
- certificate updates

---

# Why Pod Restart Helps

Pod restart forces:

1. Sidecar restart.
2. Fresh connection to Istiod.
3. New SDS synchronization.
4. New certificate retrieval.
5. New trust bundle retrieval.

Communication temporarily recovers.

However, if stale proxies remain elsewhere in the mesh, failures continue.

Therefore restart is mitigation rather than permanent resolution.

---

# Production Investigation

## Verify Certificate Expiration

Check workload certificates:

```bash
istioctl proxy-config secret <pod>
```

Inspect:

- expiration dates
- certificate chains
- trust bundles

---

## Verify Proxy Synchronization

Check synchronization status:

```bash
istioctl proxy-status
```

Look for:

```text
STALE
```

or

```text
NOT SENT
```

These indicate incomplete configuration propagation.

---

## Verify Istiod Health

Inspect:

- Istiod logs
- certificate issuance events
- SDS errors
- xDS delivery errors

---

## Compare Root Trust Bundles

Verify consistency of:

```text
istio-ca-root-cert
```

across namespaces and workloads.

---

## Verify Time Synchronization

Check:

```bash
timedatectl
```

or

```bash
chronyc tracking
```

Time drift can cause:

```text
certificate expired
certificate not yet valid
```

even with otherwise correct certificates.

---

# Short-Term Mitigation

## Rolling Restart

Force restart of critical workloads:

```bash
kubectl rollout restart deployment
```

Purpose:

- refresh Envoy sidecars
- retrieve new certificates
- retrieve updated trust bundles

---

## Validate Istiod

Confirm:

- healthy replicas
- functioning SDS
- successful certificate issuance

---

## Restore Mesh Synchronization

Identify stale proxies and reconnect them to control plane.

---

# Long-Term Fix

## Safe Root CA Rotation

Introduce overlapping trust windows.

Both old and new Root CA certificates should be trusted during migration.

Purpose:

- eliminate trust gaps
- allow gradual adoption

---

## Certificate Expiration Monitoring

Monitor:

- certificate lifetime
- SDS synchronization
- trust bundle age

Generate alerts before expiration.

---

## Automated Proxy Health Validation

Continuously monitor:

- xDS synchronization
- SDS synchronization
- stale proxy detection

---

## Improve Rotation Procedures

Introduce staged certificate rotation:

1. Deploy new trust bundle.
2. Verify propagation.
3. Rotate workload certificates.
4. Remove old Root CA after validation.

This minimizes outage risk.

---

# Key Learning

Service Mesh security depends not only on certificate issuance but also on certificate distribution and trust propagation.

A healthy infrastructure does not guarantee healthy communication.

When STRICT mTLS is enabled, certificate management becomes a critical availability dependency.

Expired certificates can create platform-wide outages even when applications, databases, and networking remain healthy.
