# Support Notes

## Core Terms

### Incident
An incident is a problem that affects the user or service right now.

### Bug
A bug is an error or defect in the system or application.

### Priority
Priority shows how urgent the issue is.

### Escalation
Escalation means passing the issue to the next level or another specialist.

### Workaround
A workaround is a temporary way to bypass the problem.

## Case 1: User cannot log in

### What I ask
- What exactly do you see on the screen?
- What is the error message?
- When did the problem start?
- Does the user enter the correct login and password?
- Does the issue happen only for one user or for others too?

### What I check
- Is the login correct?
- Is the password correct?
- Is the account locked?
- Is the service working normally?
- Is there any outage or known incident?

### Where I escalate
- To system administrator if it is an access or account issue
- To application support if it is an app-side issue
- To developers if it looks like a bug in the system

## My Reminder
In support I should think like this:
1. understand the symptom
2. ask clear questions
3. check basic causes
4. find temporary workaround if possible
5. escalate if needed


## Case 2: User cannot load page

### What I ask
- What page are you trying to open?
- What exactly happens? (blank page, error, loading forever)
- When did it start?
- Does it happen on other devices or browsers?

### What I check
- Is the URL correct?
- Is the server responding?
- Is there a network issue?
- Is there a known outage?

### Where I escalate
- To network/admin team if it's connectivity
- To backend team if server is down
- To frontend team if UI is broken


## Case 3: Data is not saving

### What I ask
- What action did you perform?
- What data did you enter?
- Did you see any error message?
- Does it happen every time?

### What I check
- Is the API request sent? (POST)
- What is the response status?
- Is there validation error?
- Is the database working?

## Case 4: User does not see their data

### Situation
User says: "I created data, but I don’t see it in the system"

### What I ask
- What exactly did you create?
- When did you create it?
- Do you see any error?
- Does the issue happen every time?

### What I check
- Was the POST request successful? (status 200/201)
- Is the data returned in response?
- Is the GET request returning the data?
- Is there a delay or caching issue?

### What I think
- Maybe POST worked but GET does not return data
- Maybe data is not saved in database
- Maybe filtering conditions are wrong (SQL issue)

### Where I escalate
- To backend if API logic is broken
- To database team if data is not stored
- To developers if it's a logic bug
### Where I escalate
- To backend if API fails
- To database team if data is not stored
- To developers if it looks like a bug
