# Incident Analysis — Week 11 Day 1

## Scenario

A new application release was deployed.

Shortly after deployment:

- API latency increased dramatically
- some requests timed out after exactly 30 seconds
- PostgreSQL CPU remained low
- Horizontal Pod Autoscaler added more API Pods
- rollback improved the situation only partially

Engineering teams suspected database performance issues.

Investigation revealed that database CPU utilization never exceeded 20%.

---

# What Problem Is Happening

The platform entered a connection coordination failure.

The primary bottleneck was not database computation.

The bottleneck was the lifecycle of database connections and transactions.

A combination of:

- connection pool saturation
- long-running transactions
- N+1 query behavior
- queue growth inside PgBouncer

caused request latency to explode.

The database spent most of its time waiting rather than computing.

Low CPU usage created a false impression that PostgreSQL was healthy.

---

# Why Low Database CPU Can Be Misleading

Database CPU measures computation.

It does not measure:

- lock contention
- connection contention
- queue waiting
- transaction scheduling delays
- client wait states

A database can be nearly idle from a CPU perspective while users experience severe latency.

Healthy CPU utilization does not guarantee healthy throughput.

---

# PgBouncer As A Bottleneck

PgBouncer protects PostgreSQL by limiting direct connections.

Clients connect to PgBouncer.

PgBouncer manages a smaller pool of server connections.

Example:

```text
500 application clients
↓
50 PostgreSQL connections
```

This improves scalability.

However, if transactions become slow, server connections remain occupied longer.

As transaction duration increases, pool throughput decreases.

Eventually clients begin waiting in queues.

---

# Transaction Pooling

In transaction pooling mode:

- server connections are assigned only during transactions
- connections return to the pool immediately after commit or rollback

Benefits:

- higher connection efficiency
- better concurrency
- reduced PostgreSQL connection pressure

Limitations:

- session variables may not work
- temporary tables become problematic
- prepared statement behavior changes

Applications must be compatible with transaction pooling semantics.

---

# N+1 Query Amplification

A common ORM anti-pattern is N+1 querying.

Example:

```text
1 query for orders
+
100 queries for order details
```

instead of:

```text
1 joined query
```

Each additional database round trip increases transaction duration.

A transaction that previously required:

```text
10 ms
```

may now require:

```text
500 ms
```

or more.

This dramatically reduces pool capacity.

---

# Queue Formation Inside PgBouncer

Assume:

```text
50 server connections
```

and:

```text
500 incoming requests
```

When all server connections become occupied:

- new requests cannot execute
- requests enter a waiting queue
- queue length grows
- latency increases

Users experience slow responses despite low database CPU usage.

---

# Head-Of-Line Blocking

Head-of-Line Blocking occurs when slow requests delay unrelated requests.

Example:

```text
49 requests = 20 ms
1 request = 25 sec
```

The long-running request occupies scarce resources.

Other requests wait behind it.

Fast operations become slow even though they are individually efficient.

This effect can spread latency throughout the platform.

---

# Tail Latency Amplification

Average latency can hide severe user-facing problems.

Example:

```text
95% requests = 100 ms
5% requests = 30 sec
```

Average metrics may appear acceptable.

However:

- slow requests consume resources longer
- queues expand
- connection pools saturate
- additional requests become delayed

The latency tail begins affecting the entire service.

This phenomenon is known as tail latency amplification.

---

# Why HPA Made Things Worse

Horizontal Pod Autoscaler reacts to resource metrics.

In this incident:

```text
CPU was not the bottleneck
```

The constrained resource was:

```text
database connections
```

Scaling API Pods increased:

- concurrency
- connection demand
- queue pressure

without increasing available database capacity.

More Pods generated more contention.

---

# Why Rollback Helped Only Partially

Rollback stopped creating new problematic transactions.

However:

- waiting requests already existed
- active transactions remained open
- queues remained populated

Recovery required time.

Distributed systems frequently exhibit recovery tails after the root cause is removed.

---

# The Significance Of Exact 30-Second Timeouts

A strong diagnostic clue was:

```text
requests failed after exactly 30 seconds
```

Fixed timeout values usually indicate:

- connection wait timeout
- pool timeout
- context deadline
- gateway timeout

The request was often waiting for a resource rather than executing database work.

---

# Backpressure Propagation

Delays spread upward through service layers.

Example:

```text
PostgreSQL
↓
PgBouncer
↓
API Service
↓
Service Mesh
↓
Ingress
↓
Client
```

A bottleneck in PostgreSQL connection acquisition becomes:

- API latency
- mesh queueing
- gateway timeout
- user-visible failure

Backpressure propagates through the entire request path.

---

# Investigation Process

## PgBouncer Metrics

Key indicators:

```text
cl_waiting
sv_active
```

Growing waiting queues combined with low database CPU strongly suggest pool saturation.

---

## PostgreSQL Activity Analysis

Inspect:

```sql
pg_stat_activity
```

Look for:

- long-running transactions
- idle in transaction sessions
- excessive transaction duration

---

## Distributed Tracing

Tracing systems reveal where latency is spent.

Important distinction:

```text
query execution time
vs
queue waiting time
```

If database execution is fast but request latency is high, the queue is usually the culprit.

---

# Production Mitigation

## Immediate Stabilization

### Terminate Problematic Transactions

Identify and remove:

- idle transactions
- long-running sessions
- blocked workers

Purpose:

- release server connections
- reduce queue pressure

---

### Limit Incoming Demand

Reduce accepted concurrency.

Prefer:

```text
fast 503
```

over:

```text
30-second timeout
```

Controlled rejection protects system stability.

---

### Tune PgBouncer

Review:

- pool size
- max client connections
- timeout values
- pooling mode

Goal:

- prevent unbounded queue growth

---

# Long-Term Improvements

## Eliminate N+1 Queries

Replace repeated ORM queries with:

- joins
- batching
- bulk loading
- dataloader patterns

Purpose:

- reduce transaction duration

---

## Read/Write Separation

Move read-heavy workloads to replicas.

Benefits:

- lower pressure on primary database
- improved connection availability

---

## Statement Timeouts

Configure strict limits.

Example:

```text
statement_timeout
```

Purpose:

- prevent runaway queries
- protect pool capacity

---

## Load Shedding

Reject excess traffic before pools become exhausted.

Purpose:

- preserve service quality
- avoid cascading failures

---

# Key Learning

- low database CPU does not guarantee healthy performance
- connection pools can become bottlenecks before databases do
- transaction duration directly affects throughput
- N+1 queries reduce effective pool capacity
- head-of-line blocking amplifies latency
- tail latency matters more than averages
- HPA cannot solve connection bottlenecks
- fixed timeout values are valuable diagnostic clues
- backpressure propagates through entire distributed systems
- throughput depends on coordination efficiency, not only computation
