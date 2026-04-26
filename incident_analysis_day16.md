# Incident Analysis — Week 6 Day 2

## Scenario
User reports: "API is slow"

Environment:
- Linux server
- Multiple running processes
- API process is not immediately identifiable

---

## My Initial Approach

Goal:
Find the API process and verify its performance

---

### 1. Identify High-Load Processes

Command:
ps aux --sort=-%cpu | head

Purpose:
- Find processes consuming the most CPU
- Narrow down potential candidates

---

### 2. Locate API Process

Commands:
ps aux | grep -E "python|node|java|gunicorn|uvicorn"

Alternative:
systemctl list-units --type=service

Purpose:
- Identify service based on runtime (Python, Node, etc.)
- Detect application entry point (e.g. app.py, server.js)

---

### 3. Identify Network Port

Commands:
ss -tulpn | grep LISTEN  
lsof -i -P -n  

Purpose:
- Map process (PID) to open port
- Confirm service is listening for requests

---

### 4. Monitor Specific Process

Command:
top -p [PID]

Purpose:
- Observe CPU and memory usage for the API process
- Detect abnormal resource consumption

---

### 5. Test API Response Time

Command:
curl -w "%{time_total}" -o /dev/null -s http://localhost:[PORT]/api/orders

Purpose:
- Measure real response time
- Confirm user-reported latency

---

### 6. Deep Inspection (if needed)

Command:
strace -p [PID]

Purpose:
- Inspect system calls
- Detect blocking operations (I/O, network)

Note:
Use carefully in production due to performance impact

---

## Decision Strategy

1. Identify process
2. Map process to port
3. Measure performance
4. Correlate with system metrics

---

## Actions

- If high CPU → investigate code or loops
- If high memory → check for leaks
- If slow response but low CPU → check I/O or dependencies
- Avoid immediate restart without diagnosis

---

## Key Learning

- Must locate service before diagnosing it
- Process + Port + Metrics = full service visibility
- System navigation is critical for real incident handling
- Direct measurement (curl) confirms real user experience
