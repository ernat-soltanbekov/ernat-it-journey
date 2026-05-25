# Incident Analysis — Week 10 Day 3

## Scenario

Production platform migrated toward event-driven architecture using Kafka.

Architecture:

```text
API Services
   ↓
Kafka
   ↓
Consumers
   ↓
PostgreSQL / Redis / Billing / Notifications
```

System processed:
- payments
- profile updates
- inventory events
- notifications
- audit logs

After traffic surge:
- notifications delayed
- balances corrected hours later
- duplicate emails observed
- duplicate charges occurred
- dashboards inconsistent

Infrastructure remained:
- healthy
- brokers alive
- Kubernetes operational
- moderate CPU usage

Kafka metrics showed:
- rapidly increasing consumer lag
- excessive rebalance activity
- retry growth

Root cause involved:
- rebalance storms
- lag amplification
- retry amplification
- hot partitions
- consumer coordination collapse
- processing backpressure

rather than:
- infrastructure failure.

---

# Event-Driven Architecture

Event-driven systems communicate through:
- asynchronous event streams

instead of:
- direct synchronous calls

Benefits:
- decoupling
- scalability
- asynchronous processing
- replay capability

Tradeoff:
- distributed coordination complexity

Systems become:
- eventually consistent
- asynchronous
- replay-sensitive

rather than:
- immediately synchronized.

---

# Kafka Architecture

Kafka is:
- distributed append-only log

Core components:
- brokers
- topics
- partitions
- offsets
- consumer groups

---

# Brokers

Kafka brokers store:
- partition logs

Responsibilities:
- replication
- persistence
- serving producers and consumers

---

# Topics

Topics represent:
- logical event streams

Examples:
- payments
- notifications
- inventory-events

Topics internally split into:
- partitions.

---

# Partitions

Partitions are:
- ordered immutable event logs

Critical properties:
- unit of parallelism
- unit of ordering
- unit of scalability

Ordering guaranteed:
- only within single partition

not:
- across entire topic.

---

# Offsets

Offsets represent:
- sequential event positions inside partition

Consumers track:
- processed position

Kafka does not delete messages after consumption.

Consumers simply:
- advance offsets.

This enables:
- replay
- recovery
- reprocessing.

---

# Consumer Groups

Consumer groups provide:
- horizontal processing scalability

Rule:

```text
one partition
→ one active consumer within group
```

Therefore:

```text
maximum parallelism
=
partition count
```

Adding more consumers than partitions:
- provides no additional throughput.

---

# Consumer Lag

Consumer lag equals:

```text
latest offset
-
committed consumer offset
```

Lag measures:
- delay between production and processing

High lag means:
- system no longer operates in real time.

Consequences:
- delayed notifications
- stale balances
- delayed reconciliation
- inconsistent dashboards

---

# Why Lag Dangerous

Lag creates:
- growing replay backlog

As backlog increases:
- consumers process larger batches
- processing latency increases
- retries accumulate
- stale state propagates longer

Large lag therefore amplifies:
- recovery time
- duplicate risk
- operational instability.

---

# Rebalancing

Kafka consumer groups require:
- partition ownership coordination

When:
- consumers join
- consumers leave
- heartbeat missed

Kafka triggers:
- rebalance

Partitions reassigned across consumers.

---

# Why Excessive Rebalancing Dangerous

Traditional eager rebalance:
- pauses all consumers temporarily

This creates:
- stop-the-world effect

During repeated rebalances:
- processing pauses repeatedly
- lag increases rapidly
- throughput collapses

This becomes:
# rebalance storm

---

# Why Autoscaling Made Incident Worse

Autoscaling added:
- new consumer Pods

Every new consumer triggered:
- another rebalance

Flow:

```text
lag increases
→ autoscaler adds Pods
→ rebalance triggered
→ processing pauses
→ lag grows more
→ autoscaler scales further
```

Positive feedback loop caused:
- coordination collapse.

---

# Delivery Semantics

## At-Most-Once

Message may be:
- lost

but:
- never duplicated

Offset committed:
- before processing.

---

# At-Least-Once

Message guaranteed processed:
- one or more times

Duplicates possible.

Most common production model.

Requires:
- idempotent consumers.

---

# Exactly-Once

Kafka supports transactional guarantees:
- primarily within Kafka ecosystem

Example:

```text
Kafka topic
→ Kafka topic
```

Once external systems involved:
- PostgreSQL
- payment gateways
- REST APIs

exactly-once semantics become:
- extremely difficult

or:
- practically impossible.

Exactly-once therefore often functions as:
- constrained guarantee
- not universal reality.

---

# Why Duplicate Events Occurred

Consumer processed event:

```text
process payment
→ external side effect succeeds
→ consumer crashes before offset commit
```

After restart:
- event replayed

Result:
- duplicate charges
- duplicate notifications

This is expected under:
- at-least-once delivery.

---

# Idempotent Consumers

Consumers must safely handle:
- duplicate delivery

Typical strategy:
- unique event_id
- durable deduplication storage
- unique constraints

Without idempotency:
- retries create corrupted business state.

Critical for:
- payments
- billing
- inventory mutations.

---

# Event Ordering Problems

Ordering guaranteed:
- only per partition

If related events distributed across partitions:
- processing order may diverge

Consequences:
- stale state
- incorrect projections
- invalid business transitions

Ordering-sensitive systems require:
- careful partition key design.

---

# Hot Partitions

Bad partition keys may create:
- uneven traffic distribution

Example:

```text
large enterprise customer
→ all events hash into one partition
```

Result:
- one overloaded consumer
- remaining consumers idle

This creates:
# partition skew

and throughput collapse.

---

# Retry Topics

Retry topics isolate:
- transient failures

Instead of:
- blocking main consumer flow

Messages moved into:
- delayed retry streams

Useful for:
- temporary downstream failures.

---

# Retry Storms

Unbounded retries dangerous.

Flow:

```text
slow downstream dependency
→ retries increase
→ consumer slows further
→ lag increases
→ more retries generated
```

Creates:
- amplification loop
- throughput collapse.

---

# Poison Pill Events

Poison pill:
- malformed or permanently failing message

Without protection:
- consumer repeatedly crashes on same offset

Entire partition stalls indefinitely.

Mitigation:
- DLQ (Dead Letter Queue).

---

# Dead Letter Queues (DLQ)

DLQ stores:
- permanently failing events

Purpose:
- isolate bad messages
- preserve stream progress
- enable later inspection

Without DLQ:
- poison messages may halt processing pipeline.

---

# Backpressure Collapse

Slow downstream dependencies create:
- consumer slowdown

Flow:

```text
slow DB
→ slow processing
→ lag growth
→ larger batches
→ heartbeat delays
→ rebalance
→ processing pauses
→ more lag
```

This becomes:
# backpressure amplification loop

Distributed systems often collapse through:
- queue growth
not:
- immediate crashes.

---

# Offset Commit Semantics

Critical ordering:

```text
process message
→ durable side effect
→ commit offset
```

If offset committed too early:
- message loss possible

If committed too late:
- duplicate replay possible

Offset timing therefore defines:
- reliability semantics.

---

# Replay Safety

Kafka retention enables:
- replaying historical events

Useful for:
- rebuilding projections
- disaster recovery
- bug correction
- reprocessing logic

Consumers therefore must be:
- replay-safe
- idempotent
- duplicate tolerant.

---

# Batching Tradeoffs

Large batches improve:
- throughput
- network efficiency

But increase:
- replay size
- processing latency
- rebalance disruption
- duplicate amplification

Batching therefore represents:
- throughput vs latency tradeoff.

---

# Cooperative Sticky Assignor

Cooperative rebalance strategy:
- minimizes partition movement

Benefits:
- avoids full stop-the-world rebalance
- reduces disruption
- stabilizes processing

Preferred for:
- large-scale consumer groups.

---

# Investigation Process

## Consumer Lag Analysis

Inspect:
- lag growth rate
- partition-specific lag
- skewed partitions

Identify:
- hot partitions
- stalled consumers.

---

# Rebalance Logs

Search logs for:
- rebalance frequency
- membership churn
- heartbeat failures

Indicators:
- coordination instability.

---

# Poison Message Detection

Inspect:
- repeatedly failing offsets
- parsing exceptions
- infinite retry loops

Purpose:
- isolate poison pills.

---

# Consumer Throughput Analysis

Measure:
- processing latency
- poll frequency
- batch duration

Critical for:
- heartbeat survivability.

---

# Partition Distribution

Validate:
- partition utilization balance
- key distribution quality

Detect:
- skew collapse.

---

# Production Mitigation Plan

## Short-Term Stabilization

- disable autoscaling
- reduce batch sizes
- increase poll intervals
- isolate poison messages
- enable DLQ
- reduce retry aggressiveness

Goal:
- stop rebalance storm.

---

# Long-Term Improvements

## Strong Idempotency

Implement:
- event_id tracking
- durable deduplication
- replay-safe consumers

Critical for:
- financial operations.

---

# Better Partitioning Strategy

Design:
- balanced partition keys

Avoid:
- hot partitions.

---

# Cooperative Rebalancing

Adopt:
- cooperative-sticky assignor

Reduce:
- stop-the-world pauses.

---

# Backpressure-Aware Consumers

Consumers should:
- regulate intake rate
- isolate downstream slowness
- avoid unbounded retries

Prevent:
- lag amplification loops.

---

# Architectural Lessons

Distributed event systems fail not because:
- events stop moving

but because:
- coordination collapses under pressure

Critical failure modes emerge from:
- rebalance storms
- lag amplification
- duplicate replay
- hot partitions
- retry loops
- processing backpressure

Reliable event-driven systems require:
- idempotent consumers
- replay-safe processing
- bounded retries
- balanced partitioning
- stable consumer coordination

---

# Key Learning

- Kafka partitions define both ordering and scalability
- consumer lag represents delayed distributed state propagation
- rebalance storms can fully halt stream processing
- autoscaling consumers may worsen instability
- exactly-once guarantees are limited in real distributed systems
- idempotent consumers are mandatory for at-least-once delivery
- hot partitions create throughput collapse
- retries and lag amplify each other through feedback loops
