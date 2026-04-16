# Incident Analysis — Week 4 Day 6

## Scenario
User reports: "I added an item to cart, but when I open the cart, it is empty"

---

## My Initial Thinking

### Questions
- What item (SKU) was added?
- When was the item added?
- Did you receive confirmation?

### First Steps
- Check request via DevTools
- Verify API response

### Problem
- I focused too much on inventory instead of cart state
- I did not consider session/user context
- I missed the importance of user state synchronization

---

## Corrected Approach

### 1. Questions to User
- Are you logged into your account?
- Does the issue happen consistently or occasionally?
- Do you see the item immediately after adding it?
- Are you using multiple devices or browser tabs?

---

### 2. First Step (Frontend - DevTools)

Open DevTools → Network:
- Check POST /cart (add item)
- Check GET /cart (retrieve cart)
- Analyze responses

---

### 3. Key Insight

This is a **state/session-related issue**, not inventory:

→ Item may be added  
→ But cart state is not preserved or retrieved correctly  

---

### 4. Diagnostic Flow

#### Step 1: Check POST /cart
- Status code
- Response (item added?)

#### Step 2: Check GET /cart
- Does it return the item?

---

#### Case A: POST success, GET empty
→ Backend/session/user_id issue

#### Case B: POST fails
→ Backend issue

#### Case C: GET has item, UI empty
→ Frontend issue

---

### 5. Possible Causes

- Cart is not persisted in backend
- Session is lost (cookies issue)
- user_id mismatch (guest vs logged user)
- API returns empty cart
- Frontend does not display cart correctly
- Race condition (intermittent issue)

---

### 6. Escalation

- Frontend → if API returns items but UI shows empty cart
- Backend → if cart is not saved or returned
- Auth/Session → if cart is tied to incorrect session or user

---

## Key Learning

- Cart is a state problem, not inventory
- Must track user/session context
- Always verify POST and GET flow
- Follow full system path: frontend → API → backend → session/storage
