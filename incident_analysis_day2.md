# Incident Analysis — Week 4 Day 2

## Scenario
User reports: "I see my orders list, but one of my recent orders is missing"

---

## My Initial Thinking

### Questions
- Have you tried refreshing the page?
- Is your internet connection stable?
- Does the issue happen again?

### First Steps
- Check data via SQL
- Test API via Postman
- Verify frontend behavior

### Problem
- I was jumping between tools without clear order
- I did not start from the user action
- I tried to go too deep (SQL) too early

---

## Corrected Approach

### 1. Questions to User
- When was the order created?
- Did you receive confirmation after creating it?
- Do you see other orders?
- Is the issue only with this order?

---

### 2. First Step (Frontend - DevTools)

Open browser DevTools → Network:
- Reload orders page
- Find GET /orders request
- Check response

---

### 3. Diagnostic Logic

#### If order is present in API response:
→ Frontend issue (data not displayed)

#### If order is NOT present:

Step 1: Check request parameters
- user_id
- filters
- status

Step 2: Test API via Postman

Step 3: Check backend / database

---

### 4. Possible Causes

- Order was not created successfully
- API does not return the order
- SQL/filter excludes the order
- Order belongs to different user/account
- Frontend does not display the data

---

### 5. Escalation

- Frontend → if API returns data but UI does not show it
- Backend → if API does not return the order
- Database → if order is not stored

---

## Key Learning

- Always start from user action
- DevTools is the primary diagnostic tool
- Do not jump directly to SQL or Postman
- Follow system layers: frontend → API → backend → database
