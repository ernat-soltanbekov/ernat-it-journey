# Consistency: stale reads and duplicate events

Based on [read-after-write notes](../day55_postgresql_replication_lag_and_read_after_write_consistency.md), [outbox notes](../day53_dual_write_problem_and_transactional_outbox.md), and [incident report 1](../incident_report_1.md).

## Exercise A: record is temporarily absent

A write succeeds, an immediate read misses it, and a later read finds it. Name two hypotheses and the evidence that separates them.

Suggested answer: a stale cache and asynchronous replica lag can both fit. Compare the same resource ID, request timestamps, read destination, cache headers/invalidation information, and primary-versus-replica observations with the owning team. Check filters and tenant/account scope as well. Eventual visibility is a clue, not proof of replication lag.

## Exercise B: database row without event

Why can “save order, then publish event” leave a saved order with no event?

Suggested answer: the process can fail between database commit and publication. An outbox stores the order and a pending event in one database transaction. A relay publishes pending events later. Relay retries can still duplicate delivery, so consumers need an idempotency strategy, usually based on a stable event or operation ID.

## Handoff prompt

State the observed inconsistency, affected resource IDs, first and last observed times, duplicate risk, and the next check. Treat the scenarios here as training cases; they are not evidence that an actual production incident occurred.
