# Containerization Strategy: Ensuring Environment Parity

This document outlines the containerization approach for the orders-api service to solve the "Works on my machine" problem and ensure seamless deployment across all environments.

## 1. Problem Statement: Environment Drift
Before containerization, the application faced risks associated with:
* **Library Mismatches**: Different versions of dependencies between local (WSL/Ubuntu) and production environments.
* **Python Runtime Inconsistency**: Potential conflicts between Python 3.9 (legacy server) and Python 3.11 (modern local dev).
* **Manual Setup Errors**: High probability of human error during manual server configuration.

## 2. Solution: Dockerization
We have implemented **Docker** to encapsulate the application and its environment into a single, immutable unit (Image).

### Key Concepts Implemented:
* **Base Image**: Utilizing `python:3.11-slim` for a minimal footprint and reduced attack surface.
* **Immutable Infrastructure**: Once built, the image remains unchanged as it moves from Staging to Production.
* **Network Binding**: Configured the application to listen on `0.0.0.0` inside the container to ensure accessibility via port forwarding.

## 3. Mature Deployment Workflow
Our container-first workflow ensures high reliability:
1. **Build**: `docker build -t my-api-v1 .` creates a snapshot of the current stable code and environment.
2. **Isolation**: Every container runs in its own namespace, preventing dependency conflicts with other services on the host.
3. **Port Mapping**: Explicit mapping (`-p 8000:8000`) provides a clear interface for the host machine.

## 4. How to Run
To spin up a fully configured environment, simply execute:
```bash
docker build -t my-api-v1 .
docker run -p 8000:8000 my-api-v1
