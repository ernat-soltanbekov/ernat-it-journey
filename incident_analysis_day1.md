# Incident Analysis — Week 4 Day 1

## Scenario
User reports: "I updated my profile (name), but changes are not saved"

---

## My Initial Approach (Before Correction)

### Questions
- Is there an error message?
- What is your login and registration date?
- Are the changes valid?

### First Steps
- Check data in SQL
- Test request via Postman (POST/GET)
- Verify input correctness

### Assumptions
- If POST = 200 and GET is empty → frontend issue
- If SQL has no data → user issue
- If API returns error → backend issue

---

## Corrected Approach (After Learning)

### 1. Questions to User
- What exactly are you changing?
- What happens after clicking "Save"?
- Do you see any error message?
- Have you tried again?

---

### 2. First Step (Critical)
Check in browser DevTools → Network:
- Is request sent when clicking "Save"?

---

### 3. Diagnostic Flow

#### If NO request:
→ Frontend issue (button / JS not working)

#### If request exists:
→ Check API response:
- Error (4xx/5xx) → backend issue
- 200 OK → continue analysis

---

### 4. If 200 OK but data not saved:
- Backend may not store data
- Database issue
- Incorrect processing logic

---

### 5. If data saved but not shown:
- API response issue
- SQL/filter problem
- Frontend display issue

---

## Key Learning

- Always start from user action (frontend)
- Do not jump directly to SQL or Postman
- 200 OK does not guarantee success
- Diagnose step-by-step across system layers

---

## Conclusion

I improved from:
- jumping between tools  
to:
- following a structured debugging flow (frontend → API → backend → database)
