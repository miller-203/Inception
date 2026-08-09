# User Documentation

*This document is intended for end users and administrators of the Inception stack. It explains how to use the deployed infrastructure day-to-day, without needing to understand the underlying code.*

## Table of Contents
- [What This Stack Provides](#what-this-stack-provides)
- [Starting and Stopping the Project](#starting-and-stopping-the-project)
- [Accessing the Website](#accessing-the-website)
- [Accessing the Administration Panel](#accessing-the-administration-panel)
- [Managing Credentials](#managing-credentials)
- [Checking That Services Are Running Correctly](#checking-that-services-are-running-correctly)
- [Troubleshooting](#troubleshooting)

---

## What This Stack Provides

The Inception stack delivers a complete, self-hosted **WordPress website**, secured behind **HTTPS**, made up of three core services:

| Service | Role |
|---|---|
| **NGINX** | The only entry point of the stack. Receives all HTTPS traffic and forwards WordPress requests to PHP-FPM. |
| **WordPress** | The CMS powering the website (content, pages, plugins, theme). |
| **MariaDB** | The database storing all WordPress content (posts, users, settings). |

*[If bonus implemented, add rows here, e.g.:]*
| **Redis** | In-memory cache that speeds up WordPress page loads. |
| **FTP** | Lets you upload/download WordPress files remotely. |
| **Adminer** | Web interface to browse and edit the MariaDB database directly. |
| **Static website** | A secondary, standalone website reachable at its own address. |

All services run as isolated Docker containers on the same host and only communicate with each other over an internal, private network — nothing except NGINX (port 443) is reachable from outside.

---

## Starting and Stopping the Project

All operations are driven by the `Makefile` at the root of the repository.

**Start the stack** (builds images if needed, then starts all containers):
```bash
make
```

**Stop the stack** (containers are stopped and removed, data is preserved):
```bash
make down
```

**Restart the stack**:
```bash
make re
```

**Fully reset the stack** (⚠️ this also deletes all persisted data — database content and WordPress files):
```bash
make fclean
```

To check what's currently running:
```bash
docker ps
```
You should see one container per service (`nginx`, `wordpress`, `mariadb`, and any bonus services), all with a status of `Up`.

---

## Accessing the Website

Once the stack is running, open a browser and go to:

```
https://yolaidi-.42.fr
```

> Note: since NGINX uses a self-signed TLS certificate (as required by the project), your browser will show a security warning on first visit. This is expected — click "Advanced" → "Proceed" (wording varies by browser) to continue.

The site only responds over **HTTPS**; plain HTTP requests are not served.

---

## Accessing the Administration Panel

The WordPress admin dashboard is available at:

```
https://yolaidi-.42.fr/wp-admin
```

Log in with the WordPress administrator account created automatically the first time the stack was launched (see [Managing Credentials](#managing-credentials) below for where to find the password).

From the dashboard you can:
- Publish and edit posts/pages.
- Manage users (an admin and at least one regular author/editor account are created by default, as required by the subject — note the admin username must **not** contain "admin" or similar in its login, per the subject's constraints).
- Install/activate themes and plugins.
- Change site settings.

*[If Adminer is implemented, add:]*
The database can also be inspected directly via Adminer at:
```
https://yolaidi-.42.fr:[adminer_port]
```
Server: `mariadb` · Username/Password: see [Managing Credentials](#managing-credentials) · Database: `wordpress` (or the name set in `.env`).

---

## Managing Credentials

All sensitive credentials (database passwords, WordPress admin password, etc.) are stored as **Docker secrets**, not in plain configuration files.

- Secret files live under `secrets/` at the root of the repository (e.g. `secrets/db_password.txt`, `secrets/db_root_password.txt`, `secrets/wp_admin_password.txt`).
- Non-sensitive settings (domain name, site title, database name, usernames) are defined in the `.env` file at the root of the repository.

**To find your login credentials:**
```bash
cat secrets/wp_admin_password.txt      # WordPress admin password
cat secrets/db_password.txt            # WordPress database user password
```

**To change a password:**
1. Edit the relevant file in `secrets/`.
2. Rebuild and restart the affected container(s):
   ```bash
   make re
   ```

> ⚠️ The `secrets/` folder and `.env` file contain sensitive data and must never be committed to a public repository. They should be listed in `.gitignore`.

---

## Checking That Services Are Running Correctly

**1. Check container status:**
```bash
docker ps
```
All containers should show `Up X minutes/hours` with no `Restarting` or `Exited` status.

**2. Check logs for a specific service:**
```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```
Look for error messages or crash loops.

**3. Check the website responds:**
```bash
curl -vk https://yolaidi-.42.fr
```
A valid HTTP response (e.g. `200 OK` or a redirect) confirms NGINX and WordPress are communicating correctly.

**4. Check the database is reachable** (from inside the MariaDB container):
```bash
docker exec -it mariadb mysql -u root -p
```
(enter the root password found in `secrets/db_root_password.txt`)

If any of these checks fail, see [Troubleshooting](#troubleshooting) below or consult [DEV_DOC.md](./DEV_DOC.md) for deeper diagnostics.

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Browser can't reach the site at all | `/etc/hosts` entry missing, or stack not running | Add the domain to `/etc/hosts`; run `docker ps` to confirm containers are up |
| "502 Bad Gateway" | WordPress/PHP-FPM container not ready or crashed | `docker logs wordpress`, then `make re` |
| Certificate warning in browser | Self-signed certificate (expected behaviour) | Accept the browser warning to proceed |
| Can't log into `/wp-admin` | Wrong credentials | Re-check `secrets/wp_admin_password.txt` |
| Data reset after restart | Volumes not correctly mounted or `make fclean` was run | Check `docker volume ls`; avoid `fclean` unless a full reset is intended |
