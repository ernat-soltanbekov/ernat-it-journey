# Docker: inspect before starting

Based on [Dockerfile](../Dockerfile), [Compose configuration](../docker-compose.yml), [requirements](../requirements.txt), and [practice.py](../practice.py).

## Exercise

Explain what can be established by reading these files, without building an image or changing configuration.

## Suggested answer

- `api` and `db` share `backend_net`; the database hostname inside the API container is `db`. `localhost` would refer to the API container itself.
- Port 8000 is published for the API. `EXPOSE` alone would not publish a host port.
- `postgres_data` is a named volume; the Compose file does not select a Windows drive.
- Short `depends_on` defines startup order; it does not establish database readiness. A healthcheck with `service_healthy` can make startup wait for readiness. [Docker documentation](https://docs.docker.com/compose/how-tos/startup-order/).
- The Dockerfile has two `FROM` instructions. The second starts the final stage; the final stage installs `requirements.txt` and runs as `appuser`.
- The current sample reads no `DATABASE_URL` and performs no database query. Database configuration alone does not demonstrate a working database connection.

For an existing training stack, inspect `docker compose ps` and bounded logs such as `docker compose logs --tail 50 api`. Redact secrets before sharing output. Distinguish “container running,” “HTTP endpoint responds,” and “business dependency works.”
