# Debugging Checklist

## 1. Understand the Issue
- What exactly did the user do?
- What is expected?
- What actually happened?

## 2. Start from User Action (Frontend)
- Did the user action trigger a request?
- Check browser DevTools (Network)

## 3. Check API Request
- Is request sent?
- What is the status code?
- What is the response body?

## 4. Analyze Response
- 200 OK → is data correct?
- 4xx/5xx → error case
- Empty data → possible logic/filter issue

## 5. Verify Parameters
- user_id
- filters
- request payload

## 6. Backend / Database Check
- Is data stored?
- Are queries correct?
- Any processing errors?

## 7. Identify Type of Issue
- Bug (500, crash)
- User error
- Empty/incorrect data
- Integration issue
- Performance issue

## 8. Decide Action
- Fixable on your side?
- Needs escalation?

## 9. Escalation (if needed)
- What works?
- What doesn’t?
- Where is the break?

## 10. Document Everything
- Incident report
- Steps to reproduce
- Observations
