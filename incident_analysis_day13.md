# Incident Analysis — Week 5 Day 6

## Scenario
User reports: "Order is created successfully but does not appear immediately"

---

## Context

- Order creation API returns success
- Order is stored in database
- Subsequent request to fetch orders does not include the new order

---

## My Initial Thinking

- I identified that the issue is not in order creation
- I suspected cache-related problem
- I suggested clearing cache after order creation

### Problem
- My explanation was too general
- I did not consider different cache strategies
- I did not explicitly describe read/write inconsistency

---

## Corrected Approach

### 1. What Is Happening

- Write operation (create order) is successful
- Read operation (get orders) returns outdated data
- Database contains correct data, but cache does not reflect it

→ This is a read/write inconsistency issue

---

### 2. First Step

Verify cache behavior after write operation:
- Does cache update after new order?
- Does cache return stale data?

---

### 3. Root Cause

- Cache is not invalidated or updated after write
- System reads from cache instead of DB
- Cache contains outdated (stale) data

---

### 4. Validation

- Create a new order
- Immediately request order list → check result
- Clear cache manually
- Request again → verify if order appears

Additional checks:
- Inspect cache TTL
- Monitor cache key updates

---

### 5. Actions

- Implement cache invalidation on write
- Update cache after successful order creation
- Adjust TTL if necessary
- Consider write-through caching strategy

---

## Key Learning

- Write success does not guarantee correct read behavior
- Cache must stay consistent with database
- Stale cache can cause user-visible inconsistencies
- Always validate assumptions with experiments
