# Incident Report 6

## Issue
User reports: "I submitted a form, but nothing happened"

## Steps to Reproduce
1. User fills out a form
2. Clicks submit button
3. No confirmation message appears
4. Data is not visible in the system

## Observed Result
- No error message
- No success message
- No data created

## Expected Result
- Form submission should create data and show confirmation

## Initial Analysis
- No feedback from system
- Could be frontend, API, or backend issue
- Need to verify if request is sent

## Possible Causes
- Frontend does not send request (button issue)
- API request fails silently
- Backend does not process request
- Data is not stored in database

## Next Actions
- Check if request is triggered (browser / Postman)
- Verify API response (status code)
- Check backend logs if available
- Confirm if data is stored
