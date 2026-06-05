# Day 56 — Envoy Connection Pool Exhaustion and Outlier Detection Cascade

## Incident

After a new API release:

- Users intermittently receive HTTP 503 responses.
- Average latency increased from 80ms to 2s.
- CPU utilization remains between 20% and 35%.
- Memory usage remains healthy.
- PostgreSQL and Redis show no signs of degradation.

Infrastructure:

Internet -> NGINX Ingress -> checkout-api -> Istio Service Mesh -> payment-service / inventory-service

Observed metrics:

NGINX:

```text
upstream timed out
```

Envoy:

```text
upstream_cx_overflow
upstream_rq_pending_overflow
```

DestinationRule:

```yaml
trafficPolicy:
  connectionPool:
    tcp:
      maxConnections: 100
    http:
      http1MaxPendingRequests: 100
      maxRequestsPerConnection: 1
```

Outlier detection was enabled one day before the incident.

```yaml
outlierDetection:
  consecutive5xxErrors: 3
```

## Root Cause

The service mesh became the bottleneck before the application layer reached its actual capacity limits.

Connection pool limits inside Envoy were configured too aggressively.

As traffic increased, Envoy exhausted available upstream connections and pending request queues.

Requests were rejected locally inside the proxy layer, producing HTTP 503 responses.

Outlier Detection interpreted these failures as unhealthy upstream instances and started ejecting healthy pods from load balancing.

The reduction in available capacity increased load on the remaining instances, creating a cascading failure pattern.

## Key Concepts

### upstream_cx_overflow

Indicates that Envoy reached the configured upstream connection limit.

New TCP connections cannot be established.

### upstream_rq_pending_overflow

Indicates that the pending request queue is full.

Additional requests are rejected immediately.

### Connection Pooling

Connection pools protect upstream services from overload.

Improper limits can artificially reduce throughput and become a bottleneck.

### maxRequestsPerConnection

```yaml
maxRequestsPerConnection: 1
```

Forces connection closure after every request.

Effects:

- TCP handshake overhead
- Increased socket churn
- More TIME_WAIT sockets
- Reduced throughput
- Faster pool exhaustion

### Outlier Detection

Outlier Detection automatically removes endpoints that appear unhealthy.

In this incident, the proxy-generated failures caused healthy services to be incorrectly ejected from rotation.

## Why CPU and Memory Look Healthy

Applications were not CPU-bound.

Most requests were blocked or rejected before reaching business logic.

The bottleneck existed inside the service mesh connection management layer rather than in application processing.

Low CPU utilization therefore did not indicate healthy request handling.

## Investigation

### Envoy Metrics

Monitor:

```text
upstream_cx_overflow
upstream_rq_pending_overflow
upstream_rq_retry
```

### Proxy Configuration

Inspect active Envoy configuration:

```bash
istioctl proxy-config cluster <pod-name> -o json
```

### Access Logs

Differentiate:

- Local Envoy-generated 503 responses
- Application-generated 503 responses

### Outlier Analysis

Identify:

- Ejected endpoints
- Ejection frequency
- Capacity reduction during incident progression

## Immediate Mitigation

### Increase Pool Limits

Increase:

```yaml
maxConnections
http1MaxPendingRequests
```

to values aligned with production traffic.

### Disable Outlier Detection

Temporarily disable endpoint ejection to stop the cascading reduction of healthy capacity.

### Enable Connection Reuse

Replace:

```yaml
maxRequestsPerConnection: 1
```

with:

```yaml
maxRequestsPerConnection: 0
```

to allow persistent connections.

## Long-Term Solutions

### Capacity Testing

Perform load testing before production rollout.

Validate service mesh limits under realistic traffic patterns.

### HTTP/2 or gRPC Adoption

Enable request multiplexing over persistent TCP connections.

Benefits:

- Lower connection overhead
- Higher throughput
- Better utilization of connection pools

### Retry Budget Controls

Prevent retry amplification during partial failures.

Limit retries and define retry budgets.

### Adaptive Circuit Breaking

Tune circuit breaker thresholds based on observed traffic and service capacity rather than static assumptions.

## Lessons Learned

The platform was not limited by application resources.

The bottleneck existed in connection management inside the service mesh.

Poorly tuned connection pools combined with aggressive Outlier Detection created a feedback loop that removed healthy capacity and amplified service degradation.

Healthy infrastructure metrics do not guarantee healthy request flow.
