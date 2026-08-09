*This project has been created as part of the 42 curriculum by yolaidi-.*

# Inception

## Table of Contents
- [Description](#description)
- [Instructions](#instructions)
- [Project Description](#project-description)
  - [Architecture Overview](#architecture-overview)
  - [Docker Usage and Sources](#docker-usage-and-sources)
  - [Virtual Machines vs Docker](#virtual-machines-vs-docker)
  - [Secrets vs Environment Variables](#secrets-vs-environment-variables)
  - [Docker Network vs Host Network](#docker-network-vs-host-network)
  - [Docker Volumes vs Bind Mounts](#docker-volumes-vs-bind-mounts)
- [Bonus Part](#bonus-part)
- [Resources](#resources)

---

## Description

**Inception** is a system administration project from the 42 curriculum. Its goal is to learn the basics of **Docker** and **system virtualization** by building a small, production-like infrastructure entirely from containers, orchestrated with **Docker Compose**.

The project consists of setting up a stack composed of:
- An **NGINX** container acting as the sole entry point to the infrastructure, serving TLS-only traffic (TLSv1.2 / TLSv1.3).
- A **WordPress** container (PHP-FPM only, no built-in web server) running the WordPress CMS.
- A **MariaDB** container serving as the database for WordPress.

Each service runs in its own dedicated container, built from a custom `Dockerfile` based on a lightweight Linux image (e.g. Debian/Alpine — *Debian*), with no ready-made images pulled directly from Docker Hub, no `latest` tags, and no use of `network: host`, `--link`, or infinite loops (e.g. `tail -f`) to keep containers alive.

The whole infrastructure is described as code and can be built and launched with a single `make` command, making it fully reproducible on any machine running Docker.

---

## Instructions

### Prerequisites
- Docker
- Docker Compose
- GNU Make
- A Linux VM (or a machine allowing you to edit `/etc/hosts`)

### Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/miller-203/Inception inception
   cd inception
   ```
2. Create your `.env` file and secrets (see [DEV_DOC.md](./DEV_DOC.md) for the full details and required variables).
3. Add your domain to `/etc/hosts` so it resolves locally:
   ```bash
   sudo echo "127.0.0.1 yolaidi-.42.fr" >> /etc/hosts
   ```

### Build & Run
```bash
make
```
This will build all Docker images and start the containers in detached mode via `docker compose`.

### Stop / Clean
```bash
make down     # stop and remove containers
make clean    # also remove images
make fclean   # also remove volumes and data (full reset)
make re       # fclean + full rebuild
```

For detailed usage, container management, and troubleshooting commands, see [USER_DOC.md](./USER_DOC.md) (end-user/admin guide) and [DEV_DOC.md](./DEV_DOC.md) (developer guide).

---

## Project Description

### Architecture Overview

```
                       ┌─────────────────────────────────────────┐
                       │            Docker Host (VM)              │
                       │                                          │
   HTTPS :443          │   ┌────────┐   fastcgi   ┌────────────┐  │
  ───────────────────► │   │ NGINX  │ ───────────► │ WordPress  │  │
                       │   └────────┘              │ (php-fpm)  │  │
                       │                            └─────┬──────┘  │
                       │                                  │ :3306   │
                       │                            ┌─────▼──────┐  │
                       │                            │  MariaDB   │  │
                       │                            └────────────┘  │
                       │                                          │
                       │        [+ bonus services here]           │
                       └─────────────────────────────────────────┘
                       inception_network (custom bridge)
```

Only NGINX exposes a port to the host (443). All other services communicate exclusively through the internal Docker network — WordPress is never reachable directly from outside, and MariaDB is only reachable by WordPress (and, if implemented, Adminer).

### Docker Usage and Sources

Every service is built from a **custom Dockerfile** written from scratch, based on the last stable version of *Debian*. No pre-built service images (e.g. `official-wordpress`, `official-mariadb`) are used; instead, each Dockerfile installs and configures the required software (nginx, php-fpm, mariadb-server, wp-cli, etc.) explicitly, which is what makes the setup fully transparent and reproducible.

Main design choices:
- **One container = one service**, each with its own Dockerfile under `srcs/requirements/<service>/`.
- **docker-compose.yml** at the root of `srcs/` orchestrates the build and startup of all services, attaches them to a dedicated network, and mounts the persistent volumes.
- **Entrypoint/config scripts** (`tools/*.sh`) handle first-boot configuration (e.g. creating the WordPress database and admin user, generating NGINX’s self-signed certificate) so that containers start ready to serve traffic without manual steps.
- **Environment variables and secrets** are injected at build/run time rather than hard-coded, so the same image can be reused across environments.
- **Restart policy**: containers are configured to restart automatically (`restart: always`/`on-failure`) to mimic production resilience.

### Virtual Machines vs Docker

| | Virtual Machines | Docker |
|---|---|---|
| Isolation level | Full OS-level isolation, own kernel | Process-level isolation, shares host kernel |
| Resource usage | Heavy (GBs of RAM/disk per VM, own kernel + OS) | Lightweight (MBs, no duplicated OS) |
| Boot time | Minutes | Seconds |
| Portability | Less portable, tied to hypervisor/image format | Highly portable via images, runs anywhere Docker runs |
| Use case | Running multiple full, isolated operating systems | Packaging and running isolated applications/services |

In this project, Docker is used instead of separate VMs per service because it gives near-equivalent isolation between services (NGINX, WordPress, MariaDB) while being far lighter and faster to build, start, and tear down — which fits the goal of quickly reproducing the whole stack with `make`.

### Secrets vs Environment Variables

| | Environment Variables | Docker Secrets |
|---|---|---|
| Storage | Stored in `.env` / `docker-compose.yml`, visible via `docker inspect` or `env` inside the container | Mounted as files in `/run/secrets/`, never shown in `docker inspect` |
| Best for | Non-sensitive configuration (hostnames, ports, feature flags) | Sensitive data (passwords, API keys, credentials) |
| Exposure risk | Higher — can leak in logs, process listings, image layers | Lower — read-only, in-memory/tmpfs mount, scoped to the container |

In this project, non-sensitive configuration (e.g. domain name, WordPress site title, admin username) is passed through the `.env` file, while all sensitive values (MariaDB root/user passwords, WordPress admin password, etc.) are stored as **Docker secrets** in the `secrets/` folder and read by the containers as files, never as plain environment variables — this avoids leaking credentials through `docker inspect` or process environment dumps.

### Docker Network vs Host Network

| | Host Network | Docker (Bridge/Custom) Network |
|---|---|---|
| Isolation | None — container shares the host's network stack directly | Isolated — containers get their own virtual network |
| Port conflicts | Possible with host services | Avoided, ports are explicitly published/mapped |
| Inter-container communication | Via `localhost`, no DNS resolution by name | Built-in DNS: containers reach each other by service name |
| Security | Container is directly exposed on host interfaces | Only explicitly published ports are reachable from outside |

This project uses a **custom Docker bridge network** (`inception_network`) rather than `network: host` (which is explicitly forbidden by the subject). This lets containers resolve and talk to each other by service name (e.g. WordPress connects to `mariadb:3306`), keeps MariaDB and WordPress unreachable from outside the Docker host, and only exposes NGINX on port 443 to the outside world.

### Docker Volumes vs Bind Mounts

| | Bind Mounts | Docker Volumes |
|---|---|---|
| Location | Any path on the host filesystem | Managed by Docker, under `/var/lib/docker/volumes/` |
| Portability | Tied to host's directory structure | Portable, managed independently of host paths |
| Managed by Docker | No | Yes (`docker volume ls`, `docker volume inspect`) |
| Typical use | Local development, quick host access to files | Persistent application data (databases, uploads) |

This project uses **named Docker volumes** (`wordpress_data`, `mariadb_data`) mounted at fixed paths on the host (`/home/[your_login]/data/...` as required by the subject) for WordPress files and the MariaDB database, so that data **persists across container restarts and rebuilds**, while still being explicitly located on the host as required.

---

## Bonus Part

*[Fill in with what you actually implemented, e.g.:]*

- **Redis** — caching for WordPress to reduce database load and speed up page rendering.
- **FTP server** — allows managing the WordPress volume's files remotely over FTP.
- **Static website** — an additional, independently built website (e.g. a portfolio page) served without a framework.
- **Adminer** — a lightweight web-based database management tool connected to MariaDB.
- **A service of your choice with strong justification** — *[explain what it is and why you added it]*.

Each bonus service follows the same principles as the mandatory part: its own Dockerfile, own container, connected through the same custom network, and configured via environment variables/secrets where relevant.

---

## Resources

### Classic References
- [Docker Official Documentation](https://docs.docker.com/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [NGINX Documentation](https://nginx.org/en/docs/)
- [WordPress Developer Resources](https://developer.wordpress.org/)
- [MariaDB Documentation](https://mariadb.com/kb/en/documentation/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
