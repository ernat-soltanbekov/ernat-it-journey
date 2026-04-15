# Incident Analysis — Week 4 Day 5

## Scenario
User reports: "I can log into my account, but I am immediately redirected back to the login page"

---

## My Initial Thinking

### Questions
- When did you try logging in?
- How many attempts were made?
- Are the credentials correct?

### First Steps
- Check request in DevTools
- Verify login processing

### Problem
- My questions were too general and not focused on session behavior
- I did not consider token/cookie handling
- I did not analyze authentication flow deeply

---

## Corrected Approach

### 1. Questions to User
- What happens immediately after login?
- Does the redirect happen instantly or after a delay?
- Have you tried another browser or incognito mode?
- Have you cleared cookies/cache?

---

### 2. First Step (Frontend - DevTools)

Open DevTools:

#### Network tab:
- Check login request (POST /login)
- Verify response (status, token/session)

#### Application tab:
- Check cookies
- Verify if session/token is stored

---

### 3. Key Insight

This is likely an **authentication/session issue**:

→ Login succeeds  
→ Session is not maintained  

---

### 4. Diagnostic Flow

#### Step 1: Check login response
- Is token/session returned?

#### Step 2: Check cookies
- Is token stored in browser?

#### Step 3: Check next request (e.g. /profile)
- Is token sent with request?

#### Step 4:
- If token missing → frontend / cookie issue
- If token present but rejected → backend issue

---

### 5. Possible Causes

- Token is not stored in cookies
- Cookies are blocked (browser/security settings)
- Session expires immediately
- Token is not sent with requests
- Backend rejects token (invalid/expired)
- Cookie configuration issue (SameSite, Secure, domain)

---

### 6. Escalation

- Frontend → if token is not stored or not sent
- Backend → if token is invalid or session fails
- Infrastructure/Security → if cookie policy blocks session

---

## Key Learning

- Authentication depends on token/session, not just login success
- DevTools (Network + Application) is critical for auth debugging
- Cookies play a key role in maintaining user session
- Must trace full auth flow: login → token → session → next request
