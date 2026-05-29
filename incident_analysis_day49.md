# Incident Analysis — Week 10 Day 7

## Scenario

Large Kubernetes platform uses:

* Prometheus
* Grafana
* Loki
* Tempo
* OpenTelemetry
* Istio Service Mesh

During production peak:

* dashboards became extremely slow
* Grafana timed out
* Prometheus memory exploded
* nodes entered OOM pressure
* observability namespace consumed massive CPU
* application workloads degraded
* scraping delays increased
* alerting became inconsistent
* some incidents were invisible during outage

Team believed:
“monitoring stack is passive infrastructure.”

After incident investigation:
observability platform itself became distributed system bottleneck.

---

# What Actually Happened

The platform entered:

* telemetry amplification collapse

Observability stack became one of the heaviest workloads in cluster.

The root problem:

* uncontrolled cardinality explosion
* excessive metric dimensionality
* aggressive scraping
* high-frequency tracing
* log ingestion overload

Monitoring system started DDoSing itself and entire cluster.

---

# Why Observability Is NOT Free

Every telemetry signal consumes resources.

Three telemetry pillars:

* metrics
* logs
* traces

All three generate:

* CPU load
* memory allocations
* network traffic
* disk IO
* serialization overhead

At small scale this overhead invisible.

At large scale:

* observability becomes infrastructure-scale distributed system.

---

# Cardinality Explosion

This is the most dangerous Prometheus failure mode.

---

# What Is Cardinality

Prometheus metric uniqueness defined by:

* metric name
* label combinations

Example:

```text
http_requests_total{service="api"}
```

Low cardinality.

Danger begins when labels include:

* user_id
* request_id
* session_id
* pod_uid
* trace_id

Example:

```text
http_requests_total{user_id="948182"}
```

Every unique label combination creates:

* entirely new time series

Millions of users:
→ millions of time series.

---

# Why Cardinality Destroys Prometheus

Each time series consumes:

* RAM
* index structures
* WAL writes
* compaction resources

Cardinality grows multiplicatively.

Example:

```text
endpoint × status × region × pod × user_id
```

Result:

* explosive memory growth

Prometheus often dies from:

* metadata scale
  not
* raw metric values.

---

# Why Histograms Become Dangerous

Latency metrics often implemented via histograms.

Example:

```text
http_request_duration_seconds_bucket
```

Each bucket creates additional series.

If histogram labels include:

* pod
* endpoint
* region
* method
* tenant

Series count explodes exponentially.

---

# Remote Write Amplification

Prometheus frequently configured with:

* remote_write

Sending metrics to:

* Thanos
* Cortex
* Mimir
* VictoriaMetrics

Problem:
every sample now duplicated across:

* WAL
* memory
* network
* remote storage

Under overload:

* queues back up
* memory pressure increases
* retries amplify traffic

Monitoring pipeline begins cascading failure.

---

# Why Scraping Can Kill Cluster

Prometheus scrapes endpoints continuously.

Large clusters may contain:

* tens of thousands of targets

Aggressive scrape intervals:

```text
scrape_interval: 1s
```

create enormous traffic.

Scraping itself consumes:

* CPU
* TLS handshakes
* serialization
* network bandwidth

Applications begin spending measurable CPU:

* serving metrics
  instead of
* serving users.

---

# OpenTelemetry Amplification

OpenTelemetry collectors aggregate:

* metrics
* traces
* logs

Improper sampling configuration catastrophic.

---

# Full Trace Sampling Disaster

If tracing configured:

```text
sampling = 100%
```

every request produces:

* spans
* metadata
* context propagation
* serialization

High traffic systems generate:

* millions of spans per minute

Tracing backend becomes bottleneck.

---

# Service Mesh Telemetry Explosion

Istio/Envoy produce extremely verbose telemetry.

Each sidecar exports:

* request metrics
* retry counters
* latency histograms
* TCP statistics
* TLS metadata

In large clusters:

* telemetry traffic itself becomes significant percentage of total traffic.

---

# Why Loki And Logging Explode

Logs deceptively expensive.

Problems:

* JSON serialization
* indexing
* compression
* ingestion buffering

Worst anti-pattern:

```text
debug logging enabled in production
```

Under incident:

* retries increase
* logs increase
* disk IO increases
* CPU increases

Feedback loop forms.

---

# Observability Feedback Loop

Classic collapse pattern:

Incident begins
→ retries increase
→ logs increase
→ metrics increase
→ tracing increases
→ monitoring overloads
→ cluster slows further
→ telemetry volume increases again

Monitoring system amplifies outage.

---

# Why Dashboards Failed First

Grafana queries often expensive.

Bad dashboards execute:

* wide PromQL scans
* regex queries
* high-resolution aggregations

Example anti-pattern:

```text
rate(http_requests_total[1h])
```

across:

* millions of series

Query engine consumes:

* huge RAM
* massive CPU
* expensive decompression

Dashboards timeout.

---

# Why Alerts Became Unreliable

Prometheus under memory pressure:

* delays rule evaluation
* skips scrapes
* misses samples

Result:

* false negatives
* delayed alerts
* alert flapping

During outage:

* observability lost observability.

---

# Investigation Process

---

# 1. Cardinality Analysis

Critical first step.

Commands:

```text
topk(20, count by (__name__)({__name__=~".+"}))
```

and:

```text
promtool tsdb analyze
```

Goal:

* identify exploding labels

---

# 2. WAL Pressure

Inspect:

* WAL growth
* compaction delays
* remote_write queue sizes

Indicators:

* WAL replay slow
* disk saturation
* memory spikes

---

# 3. Query Profiling

Find expensive dashboards.

Look for:

* unbounded regex
* high-cardinality aggregations
* long range queries

---

# 4. Trace Sampling Rates

Inspect:

* collector CPU
* span ingestion rate
* queue pressure

Check:

* dropped spans
* exporter retries

---

# 5. Log Ingestion Rate

Measure:

* bytes/sec
* label cardinality
* ingestion burst patterns

---

# Production Mitigation Plan

## Immediate Stabilization

---

# Reduce Scrape Frequency

Increase:

```yaml
scrape_interval: 30s
```

or higher.

Purpose:

* reduce telemetry traffic immediately.

---

# Disable High Cardinality Labels

Remove:

* user_id
* session_id
* request_id
* dynamic identifiers

Metrics must remain aggregate-oriented.

---

# Enable Trace Sampling

Never use:

* 100% tracing

Use:

* probabilistic sampling
* tail sampling

Example:

```text
1%
```

or less under heavy traffic.

---

# Rate Limit Logging

Disable:

* debug logging
* request body logging
* verbose retry logs

Under incident:

* logging volume must decrease
  not
* increase.

---

# Protect Cluster Resources

Apply:

* resource quotas
* limits
* dedicated observability nodes

Monitoring must never starve production workloads.

---

# Long-Term Architecture

---

# Hierarchical Observability

Separate:

* local metrics
* aggregate metrics
* long-term storage

Do not centralize everything into one Prometheus.

Use:

* federation
* Thanos
* sharding

---

# Cardinality Governance

Treat labels as:

* production-critical schema design

Establish:

* cardinality budgets
* telemetry review process

Never allow arbitrary labels into production.

---

# Adaptive Sampling

Sampling must dynamically react to:

* traffic
* incidents
* saturation

During outages:

* telemetry volume often must decrease automatically.

---

# Multi-Tier Logging

Not all logs equal.

Separate:

* audit logs
* operational logs
* debug logs

Different retention policies required.

---

# Dedicated Observability Clusters

Very large platforms isolate telemetry infrastructure.

Production cluster should not collapse because:

* monitoring collapsed.

---

# Key Learning

* observability is distributed system
* telemetry has real infrastructure cost
* cardinality destroys monitoring systems
* metrics schema design is architectural responsibility
* traces require aggressive sampling
* logs amplify incidents
* monitoring systems can DDoS production
* dashboards may become outage source
* telemetry pipelines require resource isolation
* observability must remain operational during failures
