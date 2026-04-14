# Incident Analysis — Week 4 Day 4

## Scenario
User reports: "I uploaded a file, but it does not appear in the system"

---

## My Initial Thinking

### Questions
- When was the file uploaded?
- Was there a confirmation message?
- Is the issue only with this file?
- Do other files appear normally?

### First Steps
- Check API behavior via DevTools
- Verify if upload request is processed

### Problem
- I did not consider file type/size limitations
- I did not explicitly include storage layer in analysis
- Some assumptions were too general

---

## Corrected Approach

### 1. Questions to User
- When did you upload the file?
- Did you receive a success message?
- Does the issue happen with other files?
- What is the file type and size?

---

### 2. First Step (Frontend - DevTools)

Open DevTools → Network:
- Trigger file upload
- Check:
  - upload request
  - status code
  - response body

---

### 3. Diagnostic Flow

#### If NO request:
→ Frontend issue (upload not triggered)

#### If request fails:
→ Check error (validation, size, format)

#### If request succeeds (200 OK):
→ Continue investigation

---

### 4. If 200 OK but file not visible:

Step 1:
- Check API response (file ID, metadata)

Step 2:
- Verify via API (Postman) if file exists

Step 3:
- Check backend processing

Step 4:
- Check storage layer (file saving)

---

### 5. Possible Causes

- File upload not triggered (frontend issue)
- File rejected due to size/type limit
- Backend does not store file
- Storage issue (file not saved or lost)
- API does not return uploaded file
- Frontend does not display file

---

### 6. Escalation

- Frontend → if request is not sent or UI does not show file
- Backend → if upload API fails or does not process file
- Storage → if file is not saved or missing after upload

---

## Key Learning

- Include storage layer in file-related issues
- Check file validation (size/type) early
- Follow full system flow: frontend → API → backend → storage
- Do not assume success based only on UI confirmation
