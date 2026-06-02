# Day 53 — Dual Write Problem and Transactional Outbox Pattern

## Incident Summary

An e-commerce platform experienced inconsistent order processing.

Observed symptoms:

- Orders existed in the database without corresponding Kafka events.
- Some payments were processed twice.
- Infrastructure dashboards appeared healthy.
- Kafka brokers remained operational.
- PostgreSQL showed no major performance degradation.

The incident revealed a consistency failure between database transactions and event publication.

---

## Root Cause

The system performed two independent operations:

1. Persisting business data in PostgreSQL.
2. Publishing an event to Kafka.

Example flow:

```text
INSERT order into database
        ↓
Publish event to Kafka
```

These operations were not atomic.

Failure scenarios:

### Scenario A

```text
Database commit succeeds
        ↓
Application crashes
        ↓
Kafka event never published
```

Result:

- Order exists.
- Downstream services never receive the event.

### Scenario B

```text
Kafka event published
        ↓
Application crashes before transaction completion
```

Result:

- Consumers receive an event referencing data that does not exist.

This is the classic Dual Write Problem.

---

## Why Duplicate Payments Occurred

Kafka provides at-least-once delivery semantics.

Consumer flow:

```text
Receive message
        ↓
Process payment
        ↓
Commit offset
```

If the consumer crashes after processing the payment but before committing the offset:

```text
Payment processed
        ↓
Consumer crash
        ↓
Offset not committed
        ↓
Message redelivered
```

Without idempotency protection, the payment is executed again.

---

## Delivery Semantics

### At-Most-Once

Pros:

- No duplicates.

Cons:

- Message loss is possible.

### At-Least-Once

Pros:

- No message loss.

Cons:

- Duplicates are possible.

### Exactly-Once

Exactly-once is only achievable within controlled boundaries.

For external systems:

```text
At-Least-Once Delivery
+
Idempotent Consumers
=
Practical Exactly-Once Behavior
```

---

## Transactional Outbox Pattern

The recommended solution is the Transactional Outbox Pattern.

Instead of publishing directly to Kafka:

```text
Business Table
Outbox Table
```

Within a single database transaction:

```text
Insert Order
Insert Outbox Event
Commit
```

If the transaction succeeds:

- Business data exists.
- Outbox event exists.

If the transaction fails:

- Neither exists.

Consistency is preserved.

A separate relay process publishes records from the outbox table to Kafka.

Flow:

```text
PostgreSQL
      ↓
Outbox Table
      ↓
Relay Process
      ↓
Kafka
```

---

## CDC Alternative

A common production implementation uses Change Data Capture (CDC).

Flow:

```text
PostgreSQL WAL
      ↓
Debezium
      ↓
Kafka
```

Benefits:

- No custom polling service.
- Reliable event extraction.
- Better operational scalability.

---

## Investigation Process

### Database Verification

Find orders without corresponding events.

Questions:

- Which orders exist only in PostgreSQL?
- Which events exist without valid orders?

### Kafka Analysis

Inspect:

- Consumer offsets
- Retry counts
- Redelivery frequency

### Distributed Tracing

Verify:

```text
Order Service
        ↓
Database Commit
        ↓
Kafka Publish
```

Measure failures between these steps.

---

## Immediate Mitigation

### Data Reconciliation

Create a reconciliation process that:

- Finds missing events.
- Verifies actual payment status.
- Republishes only valid events.

### Retry Reduction

Temporarily reduce aggressive retry behavior until idempotency protections are implemented.

---

## Long-Term Improvements

### Transactional Outbox

Mandatory for services performing database writes and event publication.

### Idempotency Keys

Every financial operation must contain:

```text
payment_id
request_id
order_id
```

Duplicate requests must be safely ignored.

### Unique Constraints

Enforce idempotency at the database layer.

Example:

```sql
UNIQUE(payment_id)
```

### CDC Adoption

Use Debezium-based CDC pipelines where possible.

---

## Key Lessons

Distributed systems cannot guarantee consistency through independent transactions.

Database writes and event publication must be coordinated through a reliable pattern.

Transactional Outbox provides atomicity.

Idempotent consumers provide safety against duplicate delivery.

Together they form the foundation of reliable event-driven financial systems.
