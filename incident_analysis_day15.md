# Incident Analysis — Week 6 Day 1

## Scenario
User reports: "API sometimes responds slowly"

Environment:
- Linux server access
- No predefined logs provided

---

## My Initial Approach

I started with system-level diagnostics to identify performance bottlenecks.

### 1. Quick System Check

Command:
uptime

Purpose:
- Check load average (1, 5, 15 minutes)
- Detect overall system pressure

---

### 2. Process Monitoring

Command:
htop

Purpose:
- Identify processes consuming high CPU or memory
- Observe system behavior in real time

---

### 3. Resource Analysis

I focused on:

- CPU usage (%CPU)
- Memory usage (%MEM)
- iowait (disk or DB latency indicator)

Insights:
- High CPU → heavy computation or loops
- High memory → possible memory leaks
- High iowait → waiting for disk or database

---

### 4. Disk / I/O Check

Command:
vmstat 1

Purpose:
- Monitor system performance in real time
- Identify I/O bottlenecks

---

### 5. Log Investigation

Checked:

/var/log/nginx/error.log  
/var/log/nginx/access.log  

Command:
tail -f /var/log/nginx/error.log

Also used:
journalctl -u api.service --since "10 minutes ago"

Purpose:
- Identify errors and anomalies
- Observe real-time behavior

---

### 6. Log Filtering

Commands:
grep ERROR /var/log/nginx/error.log  
journalctl -u api.service | grep ERROR  

Purpose:
- Reduce noise
- Focus on critical issues

---

## Decision Strategy

1. Identify bottleneck (CPU / Memory / I/O)
2. Correlate with logs
3. Confirm root cause

---

## Actions

- If process is stuck → investigate before restart
- If high load → analyze cause (not just scale)
- If slow DB → log and escalate for optimization

---

## Key Learning

- Must diagnose system before acting
- Server performance issues require multi-level analysis
- Logs + system metrics = full picture
- Restart is a temporary fix, not a solution
