# Incident Analysis — Week 4 Day 3

## Scenario
User reports: "I clicked 'Pay', money was deducted, but order status is still 'pending'"

---

## My Initial Thinking

### Questions
- Where and when was the payment made?
- How many times was the payment attempted?
- Is the issue related only to payment?

### First Steps
- Check transaction via developer tools
- Verify if payment is actually completed
- Check order data in database

### Problem
- I did not clearly identify the integration gap
- I jumped too quickly to database checks
- My questions were not focused on confirmation of payment and status behavior

---

## Corrected Approach

### 1. Questions to User
- When did you make the payment?
- Did you receive payment confirmation?
- Was money actually deducted from your account?
- Does the order status change over time or remain "pending"?

---

### 2. First Step (Frontend - DevTools)

Open DevTools → Network:
- Trigger payment or reload order status
- Check:
  - payment request
  - order status request
  - response status and body

---

### 3. Key Insight

This is likely an **integration issue between payment and order system**:

→ Payment is successful  
→ Order status is not updated  

---

### 4. Diagnostic Flow

#### Step 1: Check payment request
- Was it successful (200 / success)?

#### Step 2: Check order status API
- Does it return "pending" or updated status?

#### Step 3: If still "pending":
- Test API via Postman

#### Step 4:
- Check backend processing
- Verify if status update logic is triggered

#### Step 5:
- Check database (final step)

---

### 5. Possible Causes

- Payment callback not received by backend
- Backend failed to update order status
- Payment processed but not linked to order
- API returns outdated order status
- Frontend does not refresh status

---

### 6. Escalation

- Backend → if payment is successful but order status not updated
- Frontend → if API returns updated status but UI shows "pending"
- Payment system → if payment confirmation is missing

---

## Key Learning

- Identify integration gaps between services
- Do not jump directly to database checks
- Start from frontend and follow the full request flow
- Payment success does not guarantee order update
