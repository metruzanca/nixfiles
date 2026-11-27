---
name: podman-services
description: Run development backing services such as PostgreSQL, MySQL, MariaDB, Redis, MongoDB, and Kafka as named rootless podman containers, defined in the project's docker-compose.yml, instead of ad-hoc database servers, background processes, or stray /tmp data directories. Use whenever a task needs a database or other stateful service to build, test, run migrations, or reproduce a bug, even if the user does not mention containers or podman. Also use when deciding how to clean up or reuse an existing local service.
---

# Podman services

A database started ad hoc is easy to forget: it keeps a port, it keeps its data,
and nobody remembers the credentials. A named container with a named volume, a
recorded port, and a `docker-compose.yml` in the project repository leaves
behind something the next person can find, restart, and remove.

This machine runs rootless `podman` with `podman-compose`. `docker` is not the
runtime here; do not call it.

## Choose the shape first

1. **The project already defines its services.** Look for
   `docker-compose.yml`, `docker-compose.yaml`, `compose.yaml`, or a
   devcontainer config. Use what is there, including its container names,
   ports, and volumes. Do not invent a parallel setup.
2. **Default: add or extend a `docker-compose.yml` in the project repository.**
   Even when the immediate need is a single test or migration, the file is the
   durable trace: it records the image, port, credentials, and volume, and it
   lets the next person (or agent) start the same service. Start it with
   `podman compose up -d`. Commit the file with the rest of the work.
3. **No repository context at all** (a scratch directory in `/tmp`, or the user
   explicitly wants something disposable). Use a single named container with
   `--rm`, then remove it before finishing.

In all three cases the service is a container. Not a server installed with nix,
not `initdb` into a temp directory, and not an extra database created inside
somebody else's server. A compose file in the repo is what stops the instance
from being forgotten.

## Reuse before creating

Check what already exists before adding another instance or binding a port:

```bash
podman ps -a --format '{{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}'
podman volume ls
ss -ltnp | grep -E ':(5432|3306|6379|27017)' || true
```

If a matching container exists, start it (`podman start <name>`) and use it.
Do not create a second instance on a colliding port just because the first one
is stopped.

## Name, port, and volume conventions

- Name: `<project>-<service>` or `dev-<project>-<service>`, derived from the
  repository directory, for example `dev-myapp-postgres`. Stable across runs.
- Volume: a named volume such as `dev-myapp-postgres-data`. Never rely on an
  anonymous volume; it is impossible to identify later.
- Port: publish on loopback only, `127.0.0.1:<port>:5432`. Databases are not
  dev servers that need Tailnet access. If the usual port may clash, pick a
  high one (`55432`) or let podman choose with `-p 127.0.0.1::5432` and read
  the result with `podman port <name> 5432`.
- Image: pin a tag and use the fully qualified name
  (`docker.io/library/postgres:18`). Short names make podman prompt for a
  registry, which breaks non-interactive runs.

### PostgreSQL example

```bash
podman run -d \
  --name dev-myapp-postgres \
  --label dev.project=myapp \
  -e POSTGRES_USER=myapp \
  -e POSTGRES_PASSWORD=myapp \
  -e POSTGRES_DB=myapp_dev \
  -p 127.0.0.1:55432:5432 \
  -v dev-myapp-postgres-data:/var/lib/postgresql/data \
  docker.io/library/postgres:18
```

Wait for readiness rather than sleeping a fixed time, then connect:

```bash
for i in $(seq 1 30); do
  podman exec dev-myapp-postgres pg_isready -U myapp -d myapp_dev && break
  sleep 1
done
```

## Compose is the default

Write the service into `docker-compose.yml` at the project root (podman-compose
also accepts `compose.yaml`; match the file the project already uses). The file
belongs to the project repository, not to `~/nixfiles` or a scratch directory.
Give the project an explicit name so containers and volumes do not depend on
the directory name:

```yaml
name: myapp

services:
  postgres:
    image: docker.io/library/postgres:18
    environment:
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD: myapp
      POSTGRES_DB: myapp_dev
    ports:
      - "127.0.0.1:55432:5432"
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

Start and stop it with `podman compose up -d` / `podman compose down`. Keep the
data volume on `down`; use `podman compose down -v` only when the user asks to
discard the data. If a compose file already exists, add the service and its
named volume to it instead of creating a second file.

## Record the instance

With a compose file in the repo there is nothing to remember: the next person
finds the service and its credentials in version control. Add a short README or
`AGENTS.md` note only when the compose file is not self-explanatory (which
command to run, which port the app expects).

For a container created without a compose file, state the container name, port,
database, user, and password in your final message to the user. A container
nobody knows about is barely better than a forgotten server.

Use obviously fake development credentials. Never put real secrets in a compose
file, and remember the repo may be public.

## Clean up

Finish every task with a deliberate decision about the containers you touched:

- One-off container: `podman rm -f <name>`; do not leave it running.
- Named container meant to stay: leave it running and say so.
- Before you report done, run `podman ps -a` and account for anything you
  created.
- Volumes hold data. Remove the ones you created with `podman volume rm
  <name>` when the work is truly finished. Never run `podman volume prune` or
  remove containers or volumes you did not create without asking the user.

## Safety

- Do not publish a database port on `0.0.0.0` or the Tailnet interface unless
  the user explicitly asks to share it.
- Do not remove or restart a container this session did not create. It may be
  another task's database.
- Do not create a throwaway database inside a shared or managed server as a
  shortcut. That is exactly the state that gets forgotten; start a container.
