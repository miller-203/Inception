# Developer Documentation

*This document is intended for developers who want to set up, build, extend, or debug the Inception project.*

## Table of Contents
- [Prerequisites](#prerequisites)
- [Repository Structure](#repository-structure)
- [Environment Setup](#environment-setup)
- [Building and Launching the Project](#building-and-launching-the-project)
- [Managing Containers and Volumes](#managing-containers-and-volumes)
- [Data Storage and Persistence](#data-storage-and-persistence)
- [Adding a New Service](#adding-a-new-service)

---

## Prerequisites

- A Linux environment (VM recommended, per subject requirements) — *[specify distro/version used]*
- [Docker Engine](https://docs.docker.com/engine/install/) (version *[X.X]*)
- [Docker Compose](https://docs.docker.com/compose/install/) (v2 plugin, invoked as `docker compose`)
- GNU Make
- Root/sudo access (to edit `/etc/hosts` and manage system directories for volumes)

Verify your installation:
```bash
docker --version
docker compose version
make --version
```

---

## Repository Structure

```
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── .gitignore
├── secrets/                      # not committed — see below
│   ├── db_root_password.txt
│   ├── db_password.txt
│   └── wp_admin_password.txt
└── srcs/
    ├── .env                          # not committed — see below
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── bonus/
            ├── redis/
            ├── ftp/
            ├── adminer/
            ├── portainer/
            └── website/

```

*[Adjust this tree to match your actual repo layout.]*

---

## Environment Setup

### 1. Configuration file (`.env`)

Create a `.env` file at the repository root (this file is **not** committed to Git — it should be listed in `.gitignore`). Example:

```env
DOMAIN_NAME=yolaidi-.42.fr

MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user

WP_TITLE=Inception
WP_ADMIN_USER=superadmin
WP_ADMIN_EMAIL=admin@example.com
WP_USER=editor
WP_USER_EMAIL=editor@example.com
```

> The admin username must not contain "admin", "administrator", etc., as required by the subject.

### 2. Secrets

> ⚠️ **Important:** the `.env` file must only ever hold **non-sensitive** configuration (domain name, database name, usernames, titles). It must **never** contain passwords. All passwords are handled exclusively through **Docker secrets**, as required by the subject. Storing passwords in `.env` (or as plain `environment:` entries) is considered a critical mistake during evaluation, because their values are visible in plain text via `docker inspect <container>` or `docker exec <container> env`, which defeats the purpose of the exercise.

Create the `secrets/` folder at the repository root (also excluded from Git) containing one file per sensitive value, plain text, no trailing newline issues:

```bash
mkdir -p secrets
echo -n "your_mysql_root_password"   > secrets/mysql_root_password.txt
echo -n "your_mysql_password"     > secrets/mysql_password.txt
echo -n "your_wp_admin_pass"   > secrets/wp_admin_password.txt
echo -n "your_wp_user_pass"   > secrets/wp_user_password.txt
echo -n "your_ftp_pass"   > secrets/ftp_password.txt
```

**Declare them in `docker-compose.yml`** under the top-level `secrets:` key:
```yaml
secrets:
  mysql_root_password:
    file: ../secrets/mysql_root_password.txt
  mysql_password:
    file: ../secrets/mysql_password.txt
  wp_admin_password:
    file: ../secrets/wp_admin_password.txt
  wp_user_password:
    file: ../secrets/wp_user_password.txt
  ftp_password:
    file: ../secrets/ftp_password.txt
```

**Attach them to the services that need them:**
```yaml
services:
  mariadb:
    secrets:
      - mysql_root_password
      - mysql_password
  wordpress:
    secrets:
      - wp_admin_password
      - wp_user_password
      - mysql_password
  ftp:
    secrets:
      - ftp_password
```

Docker mounts each declared secret as a **read-only file** inside the container at `/run/secrets/<secret_name>` — it is never injected as an environment variable and never appears in `docker inspect`.

**Reading a secret inside a container:** the entrypoint script reads the file content at runtime and exports it locally (or passes it directly to the command that needs it), instead of relying on a pre-set environment variable:
```bash
#!/bin/sh
# example: srcs/requirements/mariadb/tools/entrypoint.sh
export MYSQL_ROOT_PASSWORD="$(cat /run/secrets/db_root_password)"
export MYSQL_PASSWORD="$(cat /run/secrets/db_password)"
# ... use these variables to initialize the database on first boot
```
The same pattern applies in the WordPress entrypoint (e.g. when calling `wp config set` or `wp core install` with `wp-cli`, the password is read from `/run/secrets/wp_admin_password` and `/run/secrets/db_password` rather than from `$WP_ADMIN_PASSWORD`).

**`.gitignore` reminder** — make sure both are excluded from version control:
```
.env
secrets/
```

### 3. Local DNS

Add the domain to your VM's hosts file so it resolves to the container's host:
```bash
echo "127.0.0.1 yolaidi-.42.fr" | sudo tee -a /etc/hosts
```

---

## Building and Launching the Project

The `Makefile` wraps all Docker Compose commands. Key targets:

```bash
make            # build images (if needed) and start all containers, detached
make build      # build/rebuild images only
make up         # start containers without rebuilding
make down       # stop and remove containers (data persists in volumes)
make clean      # down + remove built images
make fclean     # clean + remove volumes and local data directories (full reset)
make re         # fclean + make (full rebuild from scratch)
make logs       # tail logs of all services
```

Under the hood, these call `docker compose` from the `srcs/` directory, e.g.:
```bash
docker compose -f srcs/docker-compose.yml --env-file .env up -d --build
```

### Build order & dependencies
`docker-compose.yml` uses `depends_on` so that MariaDB starts before WordPress, and WordPress before NGINX. Each service's entrypoint script additionally waits for its dependency to be truly ready (e.g. WordPress's entrypoint polls MariaDB on port 3306) before proceeding, since `depends_on` alone only guarantees container *start order*, not service *readiness*.

---

## Managing Containers and Volumes

**Container inspection:**
```bash
docker ps -a                       # list all containers (running + stopped)
docker logs -f <container_name>    # follow logs live
docker exec -it <container_name> sh   # shell into a running container
docker inspect <container_name>    # full container metadata
```

**Rebuilding a single service:**
```bash
docker compose -f srcs/docker-compose.yml build wordpress
docker compose -f srcs/docker-compose.yml up -d wordpress
```

**Network inspection:**
```bash
docker network ls
docker network inspect srcs_inception_network
```

**Volume inspection:**
```bash
docker volume ls
docker volume inspect srcs_wordpress_data
docker volume inspect srcs_mariadb_data
```

**Cleaning up dangling resources during development:**
```bash
docker system prune -f          # remove stopped containers, unused networks
docker volume prune -f          # remove unused volumes (careful: irreversible)
```

---

## Data Storage and Persistence

Project data is persisted using **named Docker volumes**, bind-mounted to fixed paths on the host, as required by the subject:

| Volume | Host path | Contents |
|---|---|---|
| `wordpress_data` | `/home/yolaidi-/data/wordpress` | WordPress core files, themes, plugins, uploads |
| `mariadb_data` | `/home/yolaidi-/data/mariadb` | MariaDB database files |

These are declared in `docker-compose.yml`:
```yaml
volumes:
  wordpress_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yolaidi-/data/wordpress
  mariadb_data:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/yolaidi-/data/mariadb
```

Because volumes live outside the container's writable layer, **data survives `make down`, container crashes, and image rebuilds**. It is only removed by `make fclean` (or a manual `docker volume rm`), which deletes the underlying host directories.

To inspect the raw data on the host directly:
```bash
ls -la /home/[your_login]/data/wordpress
ls -la /home/[your_login]/data/mariadb
```

---

## Adding a New Service

To extend the stack (e.g. for a bonus service):

1. Create a new folder under `srcs/requirements/bonus/<service_name>/` with its own `Dockerfile` and any config/entrypoint scripts.
2. Add a corresponding service block in `srcs/docker-compose.yml`, attaching it to the existing `inception_network` and declaring any volumes/secrets/env vars it needs.
3. If it needs to be reachable from outside, expose the relevant port and document it in [USER_DOC.md](./USER_DOC.md).
4. Rebuild with `make re` and verify with `docker ps` / `docker logs <new_service>`.
