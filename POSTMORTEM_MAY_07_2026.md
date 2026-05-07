# Postmortem: API Latency & Cascading Failure Prevention

**Status:** RESOLVED  
**Incident Date:** 2026-05-07  
**Severity:** Critical (P1)  
**Location:** Core API Cluster

## 1. Executive Summary
A critical degradation in API performance was detected due to high latency from an upstream external service. The system successfully transitioned from a failing state to a self-healing state using the **Circuit Breaker** pattern, preventing total resource exhaustion and maintaining minimum service availability via Fallback Mode.

## 2. Incident Timeline
* **09:32:** Monitoring detected the first 2000ms delay in external service calls.
* **09:34:** `STRIKE_COUNT` reached the threshold (3 consecutive failures).
* **09:35:** **CRITICAL ALERT** triggered. Circuit Breaker state changed to `OPEN`.
* **09:36:** Automated recovery validation: API began serving immediate `timeout_fallback` responses, reducing latency from 2000ms to <200ms.

## 3. Root Cause Analysis (The 5 Whys)
1. **Why was the API slow?** Main thread was blocked waiting for external service responses.
2. **Why did it block?** Lack of enforced timeouts on the network layer for downstream calls.
3. **Why wasn't the load shed?** The system lacked an automated failure detection mechanism.
4. **Why did we miss the detection earlier?** Error budgets were not defined for sequential failures.
5. **Root Cause:** Absence of the **Circuit Breaker** architectural pattern, leading to cascading latency across the core cluster.

## 4. Corrective Actions (Action Items)
- [x] Implement `Correlation-ID` for end-to-end request tracing.
- [x] Configure **Actionable Alerts** based on error strike sequences (3/3).
- [x] Integrate automated **Circuit Breaker** logic: transition to `CIRCUIT_OPEN` state upon threshold breach.
- [ ] **Next Step:** Implement `Half-Open` state for automated service probes and recovery.

## 5. Lessons Learned
Static monitoring is insufficient for high-availability clusters. The implementation of **Resilience Patterns** (Circuit Breaker) is mandatory for core infrastructure to ensure "fail-fast" behavior and protect system resources from external dependencies.
