# GRaCe-GRC-sandbox

Local development environment for GRaCe-GRC: one Docker Compose setup with the databases and,
as they are added, the services.

> **Status:** PostgreSQL only. Services are added in later stories. No SQS, SNS or S3 yet.

## Layout

| Path | Contents |
|---|---|
| `compose/compose.yaml` | Services of the environment |
| `compose/.env.example` | Configuration defaults |
| `compose/postgres/init/` | Scripts that create the databases and users on first start |

## Prerequisites
- Docker with Docker Compose v2 (`docker compose version`)
- Port `5432` free, or another port set in `compose/.env`

## Start and stop
Run every command from the `compose` folder:

```bash
cd compose
docker compose up -d --wait
docker compose ps
docker compose down
```

`--wait` returns once every service is healthy.

## Configuration
The defaults work without any setup. To change them, copy the example file in `compose/` and edit it:

```bash
cp .env.example .env
```

| Variable | Default | Description |
|---|---|---|
| `POSTGRES_TAG` | `18-alpine` | PostgreSQL image tag |
| `POSTGRES_PORT` | `5432` | Port on your machine |
| `POSTGRES_USER` | `postgres` | Superuser |
| `POSTGRES_PASSWORD` | `postgres` | Superuser password |
| `REGULATORY_API_DB_PASSWORD` | `regulatory_api` | Password of the `regulatory_api` user |

These values are for local use only. `compose/.env` is ignored by git.

## Databases

| Database | Owner | Used by |
|---|---|---|
| `regulatory` | `regulatory_api` | [regulatory-api](https://github.com/GRaCe-GRC/regulatory-api) |

The databases and users are created the first time PostgreSQL starts
(`compose/postgres/init/`). Tables are created by each API's Flyway migrations, not here.

Connect from your machine:

```bash
docker compose exec -e PGPASSWORD=regulatory_api postgres \
  psql -h 127.0.0.1 -U regulatory_api -d regulatory
```

JDBC URL for a service running on your machine: `jdbc:postgresql://localhost:5432/regulatory`

## Reset the data
Removing the volume deletes all data; the next start creates the databases again.

```bash
docker compose down -v
docker compose up -d --wait
```

## Contributing
See the organization's [contributing guide](https://github.com/GRaCe-GRC/.github/blob/main/CONTRIBUTING.md).
Commit messages use Conventional Commits with the ticket ID, for example
`feat: GRC-28: add regulatory-api`.

## License
Licensed under the [Apache License 2.0](LICENSE).
