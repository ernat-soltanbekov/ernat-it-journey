# Incident Analysis — Week 7 Day 6

## Scenario

Production incident occurred during peak traffic:

- API unavailable for 18 minutes
- Users received HTTP 500 errors
- Payment processing stalled
- Some orders were processed twice

System was later restored.

---

## What Is a Postmortem

Postmortem is not a formal report for management.

Its purpose is:
- to convert a costly failure into operational knowledge
- to ensure the same incident cannot happen again in the same way

A serious incident must improve system resilience.

---

## Main Team Mistake

The worst possible reaction is searching for a person to blame.

Blame culture causes:
- fear
- hidden mistakes
- poor incident reporting

Correct approach:
- assume engineers acted in good faith
- analyze why the system allowed the failure

Focus:
- process
- architecture
- missing safeguards

Not personal attacks.

---

## What a Good Postmortem Contains

### 1. Summary
Short explanation of:
- what happened
- affected systems
- affected users

---

### 2. Timeline
Minute-by-minute sequence:

- incident start
- detection time
- mitigation start
- recovery time

---

### 3. Impact
Business and technical impact:

- number of affected users
- downtime duration
- financial losses
- duplicated or failed operations

---

### 4. Root Cause Analysis
Deep technical explanation of why the incident occurred.

Not:
"database failed"

But:
- why it failed
- what conditions allowed it
- why protection mechanisms failed

---

### 5. Action Items
Concrete remediation tasks:

Examples:
- add missing DB index
- increase connection pool
- add timeout protection
- improve monitoring
- create load test scenario

Tasks must be tracked in GitHub/Jira.

---

## Root Cause Analysis Example (5 Whys)

Why was API unavailable?
→ Order service crashed.

Why did it crash?
→ Database stopped responding.

Why did database stop responding?
→ Connection pool exhausted.

Why was pool exhausted?
→ Long-running query blocked table access.

Why did query become long-running?
→ Missing database index was not detected during testing.

Root Cause:
Missing index + insufficient performance testing.

---

## What Is Considered a Good Result

A successful postmortem is not a completed document.

Success means:
- corrective actions were implemented
- monitoring improved
- system became more resilient

If the same traffic spike happens again:
- system survives
- or fails gracefully

without repeating the same incident.

---

## Key Learning

- Incidents must improve the system
- Blameless culture improves reliability
- Root cause is deeper than visible symptoms
- Action items matter more than documentation
