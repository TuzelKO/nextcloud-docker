# Nextcloud Docker

[![Docker Pulls](https://img.shields.io/docker/pulls/tuzelko/nextcloud)](https://hub.docker.com/r/tuzelko/nextcloud)
[![License](https://img.shields.io/github/license/tuzelko/nextcloud-docker)](LICENSE)

A Docker solution for self-hosting [Nextcloud](https://nextcloud.com/) — a private cloud platform for file storage, sharing, and collaboration. Built on Alpine Linux with PHP and NGINX Unit, configured entirely through environment variables.

## Why Nextcloud Docker?

- 🚀 **Auto-configured** – The container downloads Nextcloud on first start and generates all PHP config files from environment variables. No manual setup.
- 📦 **Full stack included** – Comes with MariaDB, Valkey (Redis-compatible cache), OnlyOffice Document Server, and Nextcloud Talk out of the box.
- 🔐 **Secrets support** – Sensitive variables (`*_PASSWORD`, `*_SECRET`) accept a `_FILE` suffix to load values from mounted secret files (Docker Swarm compatible).
- 🐳 **Containerised** – Run it anywhere Docker runs, with consistent behavior across environments.

## Prerequisites

- Docker (≥ 20.10)
- Docker Compose (≥ 2.0) or Docker Engine with `docker compose` plugin

## Quick Start

### 1. Configure the Service

Download the [`docker-compose.yml`](examples/docker-compose.yml) file and place it in a convenient location on your disk.

Edit the file to set the required environment variables:

- `NEXTCLOUD_DOMAINS` – Comma-separated list of trusted domains (e.g. `localhost,cloud.example.com`).
- `NEXTCLOUD_MAIN_DOMAIN` – Primary domain used for URL generation (e.g. `cloud.example.com`).
- `MARIADB_PASSWORD` / `MARIADB_ROOT_PASSWORD` – MariaDB passwords.

For a full list of available variables see [Configuration Reference](#configuration-reference).

### 2. Start the Service

```bash
docker compose up -d
```

On first start the container will download the latest Nextcloud release and configure itself automatically.

### 3. Open Nextcloud

Navigate to `https://cloud.example.com` (or the domain you configured) and complete the web installer.

### 4. Stop the Service

```bash
docker compose down
```

### 5. Stop and Remove All Data

```bash
docker compose down -v
```

This deletes all Docker volumes (files, database, caches) — use with caution.

## Configuration Reference

### Required

| Variable                | Description                                                                   |
|-------------------------|-------------------------------------------------------------------------------|
| `NEXTCLOUD_DOMAINS`     | Comma-separated list of trusted domains (e.g. `localhost,cloud.example.com`). |
| `NEXTCLOUD_MAIN_DOMAIN` | Primary domain used for URL generation.                                       |
| `NEXTCLOUD_DB_TYPE`     | Database type: `mysql`, `pgsql`, or `sqlite3`.                                |

### General

| Variable                    | Default                                   | Description                                                       |
|-----------------------------|-------------------------------------------|-------------------------------------------------------------------|
| `NEXTCLOUD_SCHEME`          | `http`                                    | Protocol used for URL generation (`http` or `https`).             |
| `NEXTCLOUD_PHONE_REGION`    | —                                         | Default phone region code (e.g. `US`, `RU`).                      |
| `NEXTCLOUD_TRUSTED_PROXIES` | `10.0.0.0/8,172.16.0.0/12,192.168.0.0/16` | Comma-separated list of trusted reverse proxy IPs or CIDR ranges. |
| `NEXTCLOUD_RELEASE_URL`     | Latest release                            | Custom Nextcloud ZIP download URL (useful for pinning a version). |

### Database (required for `mysql` / `pgsql`)

| Variable                | Description                                               |
|-------------------------|-----------------------------------------------------------|
| `NEXTCLOUD_DB_HOST`     | Database host.                                            |
| `NEXTCLOUD_DB_NAME`     | Database name.                                            |
| `NEXTCLOUD_DB_USER`     | Database user.                                            |
| `NEXTCLOUD_DB_PASSWORD` | Database password. Supports `NEXTCLOUD_DB_PASSWORD_FILE`. |

### Cache

| Variable                         | Default | Description                                      |
|----------------------------------|---------|--------------------------------------------------|
| `NEXTCLOUD_CACHE_MODE`           | `apcu`  | Cache backend: `apcu`, `redis`, or `memcached`.  |
| `NEXTCLOUD_CACHE_REDIS_HOST`     | —       | Redis / Valkey host (required for `redis` mode). |
| `NEXTCLOUD_CACHE_REDIS_PORT`     | —       | Redis / Valkey port (required for `redis` mode). |
| `NEXTCLOUD_CACHE_REDIS_USER`     | —       | Redis user. Supports `_FILE`.                    |
| `NEXTCLOUD_CACHE_REDIS_PASSWORD` | —       | Redis password. Supports `_FILE`.                |
| `NEXTCLOUD_CACHE_MEMCACHED_HOST` | —       | Memcached host (required for `memcached` mode).  |
| `NEXTCLOUD_CACHE_MEMCACHED_PORT` | —       | Memcached port (required for `memcached` mode).  |

### Mail

| Variable                   | Description                                              |
|----------------------------|----------------------------------------------------------|
| `NEXTCLOUD_SMTP_MODE`      | Mail mode: `smtp` or `sendmail`. Leave unset to disable. |
| `NEXTCLOUD_SMTP_HOST`      | SMTP server hostname.                                    |
| `NEXTCLOUD_SMTP_PORT`      | SMTP server port.                                        |
| `NEXTCLOUD_SMTP_SECURE`    | Encryption: `SSL`, `TLS`, or empty.                      |
| `NEXTCLOUD_SMTP_AUTH`      | Enable SMTP authentication: `true` or `false`.           |
| `NEXTCLOUD_SMTP_AUTH_TYPE` | Auth type (e.g. `LOGIN`).                                |
| `NEXTCLOUD_SMTP_USER`      | SMTP username.                                           |
| `NEXTCLOUD_SMTP_PASSWORD`  | SMTP password. Supports `NEXTCLOUD_SMTP_PASSWORD_FILE`.  |
| `NEXTCLOUD_SMTP_FROM`      | From address user part (e.g. `cloud`).                   |
| `NEXTCLOUD_SMTP_DOMAIN`    | From address domain.                                     |

## Advanced Usage

### Pinning a Nextcloud Version

Set `NEXTCLOUD_RELEASE_URL` to a specific release ZIP:

```bash
NEXTCLOUD_RELEASE_URL=https://download.nextcloud.com/server/releases/nextcloud-30.0.0.zip
```

### Debugging

Run the container in foreground mode to see live logs:

```bash
docker compose up
```

Or check logs of a running service:

```bash
docker compose logs -f app
```

## Development & Debugging

A `Makefile` is included for developers. It simplifies building and managing the container.

### Available Make Commands

- `make init` – Copy `.env.dist` to `.env`.
- `make clean` – Remove unused Docker resources.
- `make pull` – Pull base images.
- `make build` – Build the Nextcloud Docker image.
- `make push` – Push the built image to a registry.
- `make up` – Start the service.
- `make down` – Stop the service.
- `make down-with-volumes` – Stop the service and delete volumes.
- `make restart` – Restart the service.

## License

This project is licensed under [MIT license](LICENSE).

---

**Maintainer**: [Eugene Frost](https://github.com/tuzelko)
**Repository**: [GitHub](https://github.com/tuzelko/nextcloud-docker)
**Registry**: [Docker HUB](https://hub.docker.com/r/tuzelko/nextcloud)

♥️ Issues and pull requests are welcome!