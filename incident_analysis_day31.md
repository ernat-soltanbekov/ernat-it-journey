# Incident Analysis — Week 8 Day 3

## Scenario

Team moved API and PostgreSQL into Docker containers.

After deployment:
- API could not connect to database
- localhost connections failed
- PostgreSQL data disappeared after redeploy
- containers had internet access but could not communicate with each other
- developers manually exposed random ports

CTO concluded that the team misunderstood container networking and storage.

---

## What Problem Is Happening

The team treats containers like lightweight virtual machines instead of isolated processes.

Two core container properties were misunderstood:
- network isolation
- ephemeral filesystem behavior

Each container:
- has its own network namespace
- has its own filesystem layer
- runs independently from other containers

Without proper networking and storage configuration:
- services cannot communicate reliably
- data becomes temporary

---

## Why localhost Inside Container Is a Trap

Inside container:
- localhost
- 127.0.0.1

refer only to the current container itself.

Example:

localhost:5432

tries to find PostgreSQL inside API container.

Result:
- connection failure

Each container has:
- separate loopback interface
- isolated network stack

---

## How Container Networking Works

Docker commonly uses bridge networking.

Containers connected to same Docker network can communicate internally.

Docker provides:
- internal DNS-based service discovery

Containers should communicate using:
- service names

Example:

db:5432

instead of:
- hardcoded IP addresses

because container IPs are temporary and change frequently.

---

## Why PostgreSQL Data Disappears

By default PostgreSQL stores data inside container writable layer.

Writable layer exists only while container exists.

Important distinction:

| Action | Data Persistence |
|---|---|
| docker restart | data survives |
| docker rm + recreate | data lost |

During redeploy:
- old container removed
- new clean container created

Result:
- database files disappeared

---

## Volumes vs Bind Mounts

### Bind Mounts

Host directory mapped directly into container.

Useful for:
- development
- hot reload
- debugging

Example:
- local source code synchronization

---

### Docker Volumes

Docker-managed persistent storage.

Useful for:
- production databases
- long-term persistence
- portable deployments

Volumes survive:
- container deletion
- container recreation

This makes them suitable for PostgreSQL persistence.

---

## Stateless vs Stateful Containers

### Stateless Containers

Examples:
- API
- Nginx
- workers

Can be recreated safely without losing important data.

---

### Stateful Containers

Examples:
- PostgreSQL
- Redis persistence
- Kafka

Require:
- persistent storage
- backup strategy
- recovery planning

---

## Production Networking and Storage Approach

### 1. Internal Docker Network

Services communicate through shared internal network.

Database should not be publicly exposed.

Only required public ports should be published externally.

---

### 2. Service Discovery

Containers communicate using service names:
- api
- db
- redis

instead of static IP addresses.

---

### 3. Persistent Volumes

Production databases must use Docker volumes.

Data must exist independently from container lifecycle.

---

### 4. Docker Compose

Compose defines:
- networks
- services
- volumes
- environment configuration

in declarative form.

Result:
- predictable infrastructure
- reproducible local and staging environments

---

## Key Learning

- Containers are isolated processes, not virtual machines
- localhost inside container refers only to itself
- Container filesystems are temporary by default
- Persistent data requires volumes
- Production container systems rely on internal networking and service discovery
