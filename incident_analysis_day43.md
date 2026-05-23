# Incident Analysis — Week 10 Day 1

## Scenario

Platform architecture:

```text
Clients
  ↓
API
  ↓
Redis Cache
  ↓
PostgreSQL
```

System characteristics:
- high traffic
- millions of users
- aggressive caching
- asynchronous invalidation
- background workers
- event-driven updates

User complaints:
- stale profile data
- outdated balances
- inconsistent usernames
- delayed notifications
- mobile/web inconsistency
- refresh sometimes fixes issue
- logout/login sometimes fixes issue

Infrastructure metrics remained healthy:
- Redis healthy
- PostgreSQL healthy
- low latency
- low CPU
- near-zero error rate

Root cause involved:
- stale cache state
- asynchronous invalidation delay
- eventual consistency
- race conditions
- distributed ordering problems

---

# Why Redis Cache Exists

Redis cache reduces:
- database load
- read latency
- repeated expensive queries

Common architecture:
- cache-aside pattern

Flow:

```text
Request
→ check Redis
→ cache miss
→ query PostgreSQL
→ populate cache
→ return response
```

Benefits:
- faster reads
- lower DB pressure
- improved scalability

Tradeoff:
- distributed consistency complexity

Caching converts:
- storage problem

into:
- state synchronization problem.

---

# Cache Invalidation

Cache invalidation means:
- removing or updating outdated cached data

Critical problem:
- cache does not automatically know DB changed

After database update:
- cache immediately becomes stale

If invalidation delayed:
- users continue reading outdated values.

---

# Stale Data

Stale data means:
- cached value no longer matches source of truth

Common causes:
- delayed invalidation
- async propagation lag
- race conditions
- stale replicas
- event ordering failures

Result:
- inconsistent user experience

Users may observe:
- old profile values
- outdated balances
- delayed notifications

even while infrastructure remains healthy.

---

# Eventual Consistency

Eventual consistency means:
- distributed systems converge over time

not:
- instantly

Guarantee:

```text
all replicas eventually agree
```

but:
- temporary inconsistency windows exist.

This creates:
- stale reads
- nondeterministic behavior
- user-visible inconsistency

particularly during:
- high write activity
- async replication
- delayed invalidation.

---

# Inconsistency Window

System flow:

```text
DB write
→ event publish
→ queue propagation
→ worker consume
→ cache invalidation
```

Between:
- database update
and:
- cache invalidation

there exists:
- inconsistency window

During this period:
- users read stale cache state.

---

# Race Conditions

Concurrent operations may execute:
- out of order
- with delay
- asynchronously

Example:

```text
Update version 3 arrives
→ cache updated

Delayed version 2 event arrives later
→ stale overwrite occurs
```

Without:
- version checks
- ordering guarantees

older state may overwrite:
- newer state

This produces:
- distributed inconsistency.

---

# Distributed Ordering Problems

Distributed systems do not guarantee:
- global ordering automatically

Events may be:
- duplicated
- delayed
- reordered
- replayed

Production systems therefore require:
- idempotency
- versioning
- ordering protection

to prevent:
- stale overwrites.

---

# Why Async Workers Introduced Risk

Async workers decoupled:
- writes
from:
- cache invalidation

Benefits:
- scalability
- decoupling
- lower request latency

Tradeoff:
- nondeterministic propagation timing

Failures may occur because:
- queue lag grows
- workers restart
- events delayed
- consumers overloaded

This increases:
- stale data lifetime.

---

# Why Refresh Or Logout Sometimes Fixed Issue

Refresh sometimes triggered:
- cache miss
or:
- forced revalidation

Logout/login frequently:
- bypassed stale session state
- rebuilt cache
- refreshed authentication context

This temporarily restored:
- fresh reads.

---

# TTL (Time To Live)

TTL defines:
- cache expiration duration

Example:

```text
profile_cache_ttl = 300 seconds
```

Tradeoff:

---

# Long TTL

Pros:
- fewer DB reads
- higher cache hit ratio

Cons:
- stale data persists longer

---

# Short TTL

Pros:
- fresher data

Cons:
- more DB load
- higher cache miss frequency
- increased stampede risk

TTL therefore represents:
- consistency vs performance tradeoff.

---

# Cache Stampede

Cache stampede occurs when:
- many requests simultaneously miss cache

Example:

```text
popular key expires
→ thousands of concurrent requests
→ all hit database simultaneously
```

Consequences:
- DB overload
- latency spikes
- cascading retries

Also known as:
- dogpile effect

Production mitigation:
- cache warming
- request coalescing
- jittered TTLs
- distributed locking.

---

# Cache Warming

Cache warming proactively refreshes:
- hot cache entries

before expiration occurs.

Purpose:
- reduce synchronized cache misses
- avoid DB flood
- stabilize latency

---

# Cache-Aside vs Write-Through vs Write-Behind

## Cache-Aside

Application manually manages cache.

Pros:
- flexible
- common

Cons:
- consistency complexity
- stale read risk

---

# Write-Through

Writes update:
- DB
- cache synchronously

Pros:
- stronger consistency

Cons:
- slower writes

---

# Write-Behind (Write-Back)

Writes stored:
- in cache first

Database updated asynchronously later.

Pros:
- very fast writes

Cons:
- durability risk
- data loss risk
- ordering complexity

Dangerous for:
- financial systems
- critical transactional state

---

# Read-After-Write Consistency

Users typically expect:

```text
I updated data
→ I immediately see updated value
```

Distributed caches often violate this expectation.

Production strategies:
- temporary cache bypass
- synchronous invalidation
- sticky sessions
- version-aware reads

Critical data frequently requires:
- stronger consistency guarantees.

---

# Idempotency

Idempotent processing ensures:
- duplicate events produce same final state

Important because distributed systems may:
- retry events
- replay messages
- duplicate deliveries

Without idempotency:
- repeated invalidation events may corrupt state.

---

# Why Dashboards Appeared Healthy

Infrastructure metrics measured:
- availability
- latency
- resource usage

but not:
- correctness of distributed state

Redis served responses successfully:
- even if values stale

System therefore appeared:
- operational

while users experienced:
- inconsistent application behavior.

---

# Cache Poisoning Risk

Incorrect or stale state may propagate into:
- shared cache layer

Cache then amplifies:
- inconsistency globally

Small synchronization bugs become:
- platform-wide stale state incidents.

---

# Investigation Process

## Event Timeline Analysis

Trace full propagation chain:

```text
DB update
→ event publish
→ queue delivery
→ worker consume
→ cache invalidation
```

Identify:
- propagation delays
- missing events
- worker lag

---

# Queue Monitoring

Inspect:
- consumer lag
- queue depth
- retry counts
- dead-letter queues

Purpose:
- detect invalidation delay.

---

# Redis Analysis

Inspect:
- TTL distribution
- hot keys
- eviction rates
- key expiration behavior

Useful tooling:
- Redis keyspace notifications

---

# Consistency Testing

Compare:
- DB state
vs:
- cache state

Validate:
- stale read frequency
- propagation delay
- ordering correctness

---

# Production Mitigation Plan

## Short-Term Stabilization

- reduce TTL
- invalidate cache synchronously for critical data
- bypass cache for recent writes
- increase worker capacity
- monitor queue lag

Goal:
- shrink inconsistency window.

---

# Long-Term Improvements

## Versioned Cache Entries

Store:
- object version
- update timestamp

Prevent:
- stale overwrite events.

---

# Ordering Guarantees

Use:
- partition-aware queues
- ordered event streams
- idempotent consumers

Reduce:
- out-of-order updates.

---

# Hybrid Consistency Strategy

Differentiate:
- critical state
- noncritical state

Examples:

Strong consistency:
- balances
- payments

Eventual consistency acceptable:
- notifications
- recommendations

---

# Stampede Protection

Implement:
- cache warming
- request collapsing
- distributed locks
- staggered TTL expiration

Prevent:
- synchronized DB flooding.

---

# Architectural Lessons

Caching systems fail not because:
- cache crashes

but because:
- distributed state propagation becomes nondeterministic

Distributed caches introduce:
- consistency windows
- ordering complexity
- stale state propagation
- synchronization races

Reliable backend systems require:
- careful invalidation design
- ordering guarantees
- version-aware updates
- bounded inconsistency windows

---

# Key Learning

- caching introduces distributed consistency complexity
- stale reads emerge from delayed invalidation
- async workers create inconsistency windows
- eventual consistency trades correctness for scalability
- distributed ordering failures corrupt cache state
- cache stampedes amplify backend load
- healthy infrastructure does not guarantee correct data visibility
