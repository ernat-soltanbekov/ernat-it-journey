# Incident Analysis — Week 10 Day 2

## Scenario

Production fintech-like platform experienced severe transactional degradation under high concurrency load.

Architecture:

```text
Kubernetes
  ↓
Backend API
  ↓
PostgreSQL
```

Symptoms:
- payment freezes
- hanging balance updates
- transaction retries
- random 500 errors
- increased API latency

Database metrics:
- increasing active transactions
- growing lock counts
- deadlocks detected
- blocked queries accumulating

Infrastructure remained:
- operational
- CPU not critically high
- Kubernetes healthy

Root cause involved:
- lock contention
- long-running transactions
- row-level locking
- deadlock amplification
- connection pool exhaustion

rather than:
- infrastructure failure.

---

# ACID Transactions

Database transactions provide:
- atomicity
- consistency
- isolation
- durability

---

# Atomicity

Operations complete:
- entirely
or:
- rollback entirely

Partial execution impossible.

---

# Consistency

Transactions preserve:
- database integrity rules

System remains:
- logically valid after commit.

---

# Isolation

Concurrent transactions should not:
- corrupt each other

Isolation controls:
- concurrency visibility semantics.

---

# Durability

Committed transactions survive:
- crashes
- restarts
- failures

via:
- WAL persistence.

---

# PostgreSQL MVCC

PostgreSQL uses:
- Multi-Version Concurrency Control (MVCC)

Instead of overwriting rows:
- UPDATE creates new tuple version

Readers access:
- consistent snapshots

Benefits:
- readers do not block writers
- writers do not block readers

This enables:
- high read concurrency.

---

# MVCC Limits

MVCC does NOT eliminate:
- writer vs writer conflicts

Two concurrent writes to same row still require:
- serialization

PostgreSQL therefore introduces:
- row-level locking

for conflicting writes.

---

# Row-Level Locking

Operations such as:

```sql
SELECT ... FOR UPDATE
UPDATE
DELETE
```

acquire:
- exclusive row locks

Purpose:
- prevent concurrent modification corruption

If another transaction attempts same row:
- it waits until lock released.

This creates:
- lock queues.

---

# Hot Rows

Hot rows are:
- heavily contended records

Examples:
- account balances
- inventory counters
- global statistics rows

High concurrency on same row creates:
- serialization bottleneck

Scaling compute infrastructure does not solve:
- logical contention bottlenecks.

---

# Lock Queue Amplification

Example:

```text
T1 holds lock
T2 waits
T3 waits
T4 waits
```

Waiting transactions consume:
- DB connections
- memory
- worker capacity
- API resources

As queues grow:
- connection pools exhaust
- request latency explodes
- API appears frozen

even while:
- CPU remains normal.

---

# Why CPU Stayed Normal

Waiting transactions:
- sleep on locks

They are not:
- actively computing

Therefore:
- CPU utilization remains moderate

while:
- concurrency coordination collapses.

This is common in:
- transactional bottlenecks.

---

# Long-Running Transactions

Long transactions dangerous because they:
- retain locks longer
- retain MVCC snapshots longer
- delay cleanup
- increase contention windows

Typical anti-pattern:

```text
BEGIN
→ update balance
→ external API call
→ reconciliation logic
→ commit
```

During entire operation:
- locks remain held.

This dramatically increases:
- contention probability.

---

# MVCC Side Effects Of Long Transactions

Old row versions cannot be cleaned while:
- old transactions remain active

Consequences:
- table bloat
- index bloat
- vacuum lag
- storage amplification

Long-running transactions therefore damage:
- both concurrency
and:
- storage efficiency.

---

# Deadlocks

Deadlock occurs when:

```text
T1 holds row A
→ waits for row B

T2 holds row B
→ waits for row A
```

Both transactions wait forever.

PostgreSQL detects cycle and aborts one transaction.

Typical error:

```text
ERROR: deadlock detected
```

Deadlocks increase under:
- high contention
- inconsistent locking order
- long transactions.

---

# Isolation Levels

## READ COMMITTED

Default PostgreSQL isolation.

Each query sees:
- committed state at query start

Allows:
- non-repeatable reads

Good balance between:
- consistency
- concurrency

---

# REPEATABLE READ

Transaction sees:
- stable snapshot

Prevents:
- non-repeatable reads

Higher isolation cost:
- increased contention risk.

---

# SERIALIZABLE

Strongest isolation.

Database detects:
- unsafe concurrent execution

May abort transactions with:

```text
could not serialize access
```

Provides strongest correctness.

Tradeoff:
- lower throughput
- more retries
- higher contention.

---

# Contention Collapse

Database degradation often caused by:
- coordination collapse

not:
- raw overload

Flow:

```text
hot rows
→ lock queues
→ waiting transactions
→ pool exhaustion
→ retries
→ more contention
→ cascading latency
```

This creates:
- concurrency collapse dynamics.

---

# Retry Storms At Database Layer

Applications often retry:
- deadlocks
- serialization failures
- lock timeouts

Under heavy contention:
- retries amplify transaction density

Result:
- self-generated overload loop

Similar to:
- distributed retry storms.

---

# Optimistic vs Pessimistic Locking

## Pessimistic Locking

Uses:
- explicit locks
- SELECT FOR UPDATE

Pros:
- strong protection

Cons:
- lock queues
- contention amplification

---

# Optimistic Locking

Uses:
- version checks

Example:

```sql
UPDATE accounts
SET balance = new_balance,
    version = version + 1
WHERE id = :id
  AND version = :expected_version;
```

Pros:
- avoids long lock waits
- improves concurrency

Cons:
- retries required on conflicts

Works best when:
- contention relatively low.

---

# Connection Pool Exhaustion

Database connections limited.

Example:

```text
pool size = 100
```

If transactions block:
- all connections occupied

New requests cannot:
- obtain DB connection

API threads begin:
- hanging
- timing out

Entire platform appears:
- frozen

despite:
- moderate DB CPU usage.

---

# Idempotent Financial Operations

Retries dangerous in financial systems.

Without idempotency:
- duplicate charges possible

Production systems require:
- idempotency keys
- replay-safe operations
- duplicate suppression

especially for:
- payments
- transfers
- balance mutations.

---

# Investigation Process

## pg_stat_activity

Inspect:
- waiting queries
- active transactions
- long-running sessions
- lock waits

Critical fields:
- wait_event_type
- query duration
- transaction age

---

# pg_locks

Analyze:
- lock types
- blocking chains
- lock ownership

Purpose:
- identify contention hotspots.

---

# Deadlock Logs

Inspect PostgreSQL logs for:

```text
deadlock detected
```

Logs reveal:
- conflicting queries
- lock acquisition order
- blocked resources

---

# Transaction Duration Analysis

Find:
- unusually long transactions

Common causes:
- external calls inside transaction
- slow reconciliation workers
- oversized transaction scope

---

# Connection Pool Metrics

Inspect:
- pool utilization
- waiting clients
- acquisition latency

Detect:
- pool starvation.

---

# Production Mitigation Plan

## Short-Term Stabilization

- reduce transaction scope
- terminate stuck workers
- introduce lock timeouts
- reduce retry aggressiveness
- isolate reconciliation jobs
- shorten transaction lifetime

Example:

```sql
SET lock_timeout = '2s';
SET idle_in_transaction_session_timeout = '5s';
```

Goal:
- stop lock queue growth.

---

# Long-Term Improvements

## Transaction Scope Reduction

Keep transactions:
- minimal
- local
- short-lived

Avoid:
- network calls inside transactions.

---

# Lock Ordering Discipline

Enforce:
- deterministic lock acquisition order

Purpose:
- reduce deadlock probability.

---

# Hot Row Decomposition

Shard highly contended entities:
- balances
- counters
- inventory

Reduce:
- single-row contention bottlenecks.

---

# Optimistic Concurrency

Adopt:
- version-based updates

Reduce:
- lock queue amplification.

---

# Retry Governance

Implement:
- bounded retries
- exponential backoff
- retry budgets

Prevent:
- retry-driven collapse.

---

# Architectural Lessons

Databases frequently fail because:
- concurrency coordination collapses

not because:
- hardware overloaded

Critical bottlenecks often emerge from:
- hot rows
- lock queues
- transaction scope
- retry amplification
- pool exhaustion

Reliable backend systems require:
- short transactions
- bounded contention
- careful concurrency design
- retry-aware architecture

---

# Key Learning

- MVCC reduces read/write contention but not write/write conflicts
- long transactions amplify lock lifetime
- deadlocks emerge from cyclic waiting
- contention collapse often occurs with normal CPU usage
- retries can amplify DB overload
- connection pool exhaustion freezes entire backend
- hot rows create logical scalability bottlenecks
- transaction scope determines concurrency survivability
