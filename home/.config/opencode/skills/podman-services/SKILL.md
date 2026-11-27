---
name: podman-services
description: Use podman (or docker where that is what is available) to run local infrastructure such as PostgreSQL, MySQL, Redis, MongoDB, and Kafka as named containers defined in the project's docker-compose.yml. Use whenever a task needs a local database or other stateful service, instead of installing a server, starting a background process, or creating a one-off database.
---

# Local infrastructure runs in containers

Use `podman` for local infra: databases, caches, queues, brokers. Do not install
a server with nix, start a background process, `initdb` into a temp directory,
or create a throwaway database inside an existing server.

- Default: add or extend `docker-compose.yml` in the project repository and start
  it with `podman compose up -d`. Commit the file.
- Use a named volume, a loopback port (`127.0.0.1:...`), a pinned fully qualified
  image (`docker.io/library/postgres:18`), and fake development credentials.
- Check `podman ps -a` first and reuse an existing container instead of starting
  a duplicate.
- With no repository context, use a named container with `--rm` and remove it
  when done.
- If you leave anything running, report its name, port, database, and
  credentials.
- Do not remove containers or volumes this session did not create.
