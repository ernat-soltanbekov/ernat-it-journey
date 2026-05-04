# Incident Analysis — Week 7 Day 3

## Scenario
User reports:
"After introducing timeouts, API returns errors more frequently instead of slow responses"

---

## Observations

- External service latency:
  - ~70% → 200–300ms
  - ~30% → 2–3 seconds
- Timeout is set to 1 second
- Fail-fast strategy is enabled

---

## What Is Happening

- Timeout cuts off slow but potentially successful responses
- 30% of requests are prematurely terminated
- System becomes faster but less successful

→ Result:
Latency improves, but error rate increases

---

## Core Problem

- Timeout is too aggressive for real latency distribution
- System prioritizes responsiveness over success rate
- No adaptive strategy for handling slow responses

---

## Trade-Off

- Responsiveness (fast failure)
- Availability / Success rate (waiting longer)

System must balance both based on business needs

---

## Solutions

### 1. Bounded Retry (Balanced Approach)

- Keep short timeout (e.g., 1s)
- Retry failed requests within a total deadline (e.g., 2–3s)
- Limit number of retries

Result:
- Improves success rate without long blocking

---

### 2. Fallback / Partial Success

- Provide alternative response if dependency fails

Examples:
- Show cached or popular data
- Return partial results

Result:
- Avoids hard failures
- Maintains user experience

---

### 3. Asynchronous Processing

- Accept request and process in background
- Return immediate acknowledgment

Result:
- Decouples user experience from slow dependencies
- Handles long-running operations safely

---

## Key Learning

- Timeout transforms latency variability into deterministic failures
- Fast failure is not always better than slow success
- System design must reflect business priorities
- Graceful degradation improves user experience
