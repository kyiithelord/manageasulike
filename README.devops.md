# DevOps Guide (Local Production-like Operations)

This guide explains how to run and maintain the stack locally in a production-like way using Docker Compose profiles, with reverse proxy, backups, healthchecks, ulimits, and log rotation.

## Prerequisites

- Docker + Docker Compose v2
- Free ports:
  - 8069 (nginx → Odoo HTTP)
  - 8072 (Odoo longpolling/bus)
  - 5433 (Postgres exposed host port)

## Services & Profiles

- `db` (Postgres): dev & prod
- `odoo` (Application): dev & prod
- `proxy` (nginx): prod only
- `backup` (nightly pg_dump): prod only

Profiles let you run dev or prod modes independently:
- Dev: `--profile dev` (direct Odoo on 8069, workers=0)
- Prod: `--profile prod` (nginx on 8069, `proxy_mode = True`, backups)

## Start (Production-like)

Example: Odoo 19

```bash
# Build and start db, app, proxy, and backup
ODOO_VERSION=19 docker compose --profile prod up -d --build db odoo proxy backup

# Check health and logs
docker compose ps
docker compose logs --since=5m db odoo proxy backup

# Access Odoo via nginx
# http://localhost:8069
```

## Configuration Files

- `config/odoo.conf` (prod):
  - `proxy_mode = True` (behind nginx)
  - `workers = 2` (tune as needed)
  - Memory/time limits set
- `config/nginx.conf`:
  - Proxies 8069 → Odoo and `/websocket` → longpolling (8072)
  - `client_max_body_size 128m`, gzip enabled, basic security headers
- `docker-compose.yml`:
  - `stop_grace_period: 60s` for `db` and `odoo`
  - Healthchecks for `db`, `odoo`, and `proxy`
  - ulimits (nofile 65536) for `odoo` and `proxy`
  - Log rotation for all services
  - `backup` service runs nightly `pg_dump`

## Backups

- Destination: `odoo-backups` volume mounted at `/backups` in `backup` container
- Format: `pg_dump -F c` (custom) → e.g., `odoo-YYYYmmdd-HHMMSS.dump`
- Retention: dumps older than 7 days are removed nightly

Check backups:
```bash
docker run --rm -v odoos_odoo-backups:/backups alpine ls -lah /backups
```

Copy a backup to host:
```bash
docker run --rm -v odoos_odoo-backups:/backups -v "$PWD":/host alpine cp /backups/odoo-YYYYmmdd-HHMMSS.dump /host/
```

Restore example:
```bash
# Create a new database
createdb -h localhost -p 5433 -U odoo odoo_restored

# Restore into it
pg_restore -h localhost -p 5433 -U odoo -d odoo_restored --no-owner --no-privileges odoo-YYYYmmdd-HHMMSS.dump
```

## Operations

- Start/Stop:
```bash
docker compose --profile prod up -d db odoo proxy backup
docker compose --profile prod down
```
- Restart Odoo only:
```bash
docker compose restart odoo
```
- Rebuild Odoo after image or addon changes:
```bash
docker compose --profile prod up -d --build odoo
```
- Logs and health:
```bash
docker compose ps
docker compose logs -f --tail=100 db odoo proxy backup
```

## Upgrades and Rollbacks

- Always ensure a fresh backup before upgrading.
- Upgrade Odoo version (e.g., 18 → 19):
```bash
ODOO_VERSION=19 docker compose --profile prod up -d --build db odoo proxy backup
```
- Validate app flows, then keep.
- If needed, rollback:
```bash
ODOO_VERSION=18 docker compose --profile prod up -d --build db odoo proxy backup
# Restore DB from last good dump if schema is incompatible
```

## Resource Tuning

- Odoo (`config/odoo.conf`):
  - `workers`: scale with CPU cores and RAM
  - memory/time limits already set; adjust based on usage
- Postgres:
  - Defaults are fine for light workloads; consider tuned configs for heavy usage
- ulimits:
  - `nofile` set to 65536 for app and proxy

## Security Notes (if exposed to the Internet)

- Change default credentials and admin master password (`config/odoo.conf`)
- Enable TLS:
  - Switch to Traefik/Caddy for auto certificates, or
  - Add Certbot to nginx setup
- Review security headers/CSP in `config/nginx.conf` for your custom assets

## Troubleshooting

- Odoo cannot connect to DB:
  - Check `db` health (`docker compose ps`) and credentials in `config/odoo.conf`
- Proxy unhealthy:
  - Transient during startup; we extended retries/start period
- Longpolling/websocket 502:
  - Ensure Odoo longpolling (8072) is up and reachable from nginx

## Versioning Strategy

- Use `ODOO_VERSION` to select any official Odoo version (e.g., 12–19)
- Maintain separate databases per major version
- Document changes in a CHANGELOG and back up before upgrades

---

With this setup, you can run local production-like Odoo reliably, with backups, healthchecks, and a clear upgrade/rollback process.
