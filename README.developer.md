# Developer Guide (Local Customization)

This guide explains how to run Odoo locally for development using Docker Compose, work on custom addons in `./addons/`, and switch Odoo versions easily.

## Prerequisites

- Docker + Docker Compose v2
- Free ports on your machine:
  - 8069 (Odoo HTTP in dev)
  - 8072 (Odoo longpolling/bus)
  - 5433 (Postgres host port)

## Project Structure

- `docker-compose.yml` — Base stack (dev & prod profiles supported)
- `docker-compose.override.yml` — Dev overrides (expose 8069, dev config)
- `config/odoo.dev.conf` — Dev settings (workers=0, debug logs)
- `config/odoo.conf` — Prod settings (proxy mode)
- `config/nginx.conf` — Nginx reverse proxy (prod)
- `Dockerfile` — Builds Odoo image with extra packages and mounts addons
- `addons/` — Your custom modules live here

## Quick Start (Odoo 19 example)

```bash
# Start Postgres + Odoo for development (workers=0, direct port 8069)
ODOO_VERSION=19 docker compose --profile dev up -d db odoo

# Check status and logs
docker compose ps
docker compose logs -f --tail=100 db odoo

# Open Odoo
# http://localhost:8069
```

## Create a Database

- Go to `http://localhost:8069/web/database/manager`
- Master password (from `config/odoo.dev.conf`): `admin`

## Working on Custom Addons

- Put your modules in `./addons/`
- Update a module after code changes:
  - From UI: Apps → Update Apps List → Upgrade your module
  - Or CLI:
    ```bash
    docker compose exec odoo odoo -u your_module -d your_db --stop-after-init
    ```

## Switching Odoo Version

Use the official tags (e.g., 12–19). Always keep one database per major version unless you are migrating.

```bash
# Stop the dev stack
docker compose --profile dev down

# Start with another version (example: Odoo 18)
ODOO_VERSION=18 docker compose --profile dev up -d --build db odoo
```

Notes:
- Do not open a DB created on a higher major version with a lower one.
- Rebuild (`--build`) after changing Odoo version or Dockerfile dependencies.

## Useful Dev Commands

```bash
# Shell inside Odoo container
docker compose exec odoo bash

# PSQL inside Postgres container
docker compose exec db psql -U odoo -d odoo

# Reset the dev environment completely (CAUTION: removes volumes)
docker compose --profile dev down -v
```

## Common Issues

- Port already in use: stop the conflicting process or change host ports in `docker-compose.yml`/override.
- Addon import errors: verify `addons_path` in `config/odoo.dev.conf` and module `__manifest__.py`.
- Longpolling problems: ensure port 8072 is not blocked by a firewall.

## Recommended Workflow

1. Start dev stack with your desired `ODOO_VERSION`.
2. Create a fresh DB for that version.
3. Iterate on modules in `./addons/`.
4. Use UI or CLI to upgrade modules.
5. Commit small, frequent changes.

Happy hacking! 🙌
