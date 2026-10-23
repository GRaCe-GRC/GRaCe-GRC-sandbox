# GRaCe-GRC-sandbox

Local development environment for GRaCe-GRC: one Docker Compose setup with the databases and the
services.

> **Status:** PostgreSQL, the Regulatory API, the regulatory ingestion service and the admin console service. More services are added in later stories. No SQS, SNS or S3 yet.

## Layout

| Path | Contents |
|---|---|
| `compose/compose.yaml` | Services of the environment |
| `compose/compose.build.yaml` | Override that runs locally built images instead of the published ones |
| `compose/.env.example` | Configuration defaults |
| `compose/postgres/init/` | Scripts that create the databases and users on first start |
| `compose/healthcheck/` | Probe used by the Java services' healthchecks |

## Prerequisites
- Docker with Docker Compose v2 (`docker compose version`)
- Ports `5432`, `8080`, `8081` and `8082` free, or other ports set in `compose/.env`

## Start and stop
Run every command from the `compose` folder:

```bash
cd compose
docker compose up -d --wait
docker compose ps
docker compose down
```

`--wait` returns once every service is healthy.

## Services

| Service | Image | Port | Depends on |
|---|---|---|---|
| `postgres` | `postgres:18-alpine` | `5432` | |
| `regulatory-api` | `ghcr.io/grace-grc/regulatory-api` | `8080` | `postgres` (healthy) |
| `regulatory-ingestion-service` | `ghcr.io/grace-grc/regulatory-ingestion-service` | `8081` | `regulatory-api` (healthy), called at `http://regulatory-api:8080` |
| `admin-console-service` | `ghcr.io/grace-grc/admin-console-service` | `8082` | `regulatory-ingestion-service` (healthy), called at `http://regulatory-ingestion-service:8080` |

```bash
curl -i -H 'Content-Type: application/json' \
  -d '{"name":"European Banking Authority","jurisdiction":"EU","createdBy":"me"}' \
  http://localhost:8081/api/v1/authorities
curl http://localhost:8081/api/v1/authorities
curl http://localhost:8080/api/v1/authorities
```

The admin console service serves the dashboard API on port `8082`:

```bash
curl -i -H 'Content-Type: application/json' \
  -d '{"name":"Financial Conduct Authority","jurisdiction":"UK"}' \
  http://localhost:8082/api/dashboard/authorities
curl http://localhost:8082/api/dashboard/authorities
```

It sets `createdBy` to `admin-console` and creates the authority through the ingestion service.

The first request creates an authority through the ingestion service (`201` with a `Location`
header); the other two read it through the ingestion service and directly from the Regulatory API.

Images use the `latest` tag by default. `docker compose up` does not download a newer `latest` on
its own, so update them first:

```bash
docker compose pull
docker compose up -d --wait
```

To run a specific release, set the tag in `compose/.env` (for example `REGULATORY_API_TAG=0.1.0` or
`REGULATORY_INGESTION_SERVICE_TAG=0.1.0`, `ADMIN_CONSOLE_SERVICE_TAG=0.1.0`).
The published images are `linux/amd64`; on Apple silicon they run under emulation and start more
slowly.

### Healthchecks
The service images have no shell, `curl` or `wget`, and their Java runtime cannot run a `.java`
file directly. The one-shot `healthcheck-probe` service compiles `compose/healthcheck/HealthCheck.java`
with a JDK image into a shared volume, and each Java service runs it with its own Java runtime
against `/actuator/health`. `--wait` returns once every service is healthy.

### Running a local build
To try changes before they are released, build the image in the service repository and start the
sandbox with the override:

```bash
(cd ../../regulatory-api && ./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=regulatory-api:local)
(cd ../../regulatory-ingestion-service && ./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=regulatory-ingestion-service:local)
(cd ../../admin-console-service && ./mvnw spring-boot:build-image -Dspring-boot.build-image.imageName=admin-console-service:local)
docker compose -f compose.yaml -f compose.build.yaml up -d --wait
```

The override only changes the images to `regulatory-api:local`, `regulatory-ingestion-service:local`
and `admin-console-service:local` and never pulls them, so build them before using it.

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
| `HEALTHCHECK_JDK_TAG` | `25-jdk` | `eclipse-temurin` image that compiles the healthcheck probe |
| `REGULATORY_API_IMAGE` | `ghcr.io/grace-grc/regulatory-api` | Regulatory API image |
| `REGULATORY_API_TAG` | `latest` | Regulatory API image tag |
| `REGULATORY_API_PORT` | `8080` | Regulatory API port on your machine |
| `REGULATORY_API_LOCAL_IMAGE` | `regulatory-api:local` | Image used by `compose.build.yaml` |
| `REGULATORY_INGESTION_SERVICE_IMAGE` | `ghcr.io/grace-grc/regulatory-ingestion-service` | Ingestion service image |
| `REGULATORY_INGESTION_SERVICE_TAG` | `latest` | Ingestion service image tag |
| `REGULATORY_INGESTION_SERVICE_PORT` | `8081` | Ingestion service port on your machine |
| `REGULATORY_INGESTION_SERVICE_LOCAL_IMAGE` | `regulatory-ingestion-service:local` | Image used by `compose.build.yaml` |
| `ADMIN_CONSOLE_SERVICE_IMAGE` | `ghcr.io/grace-grc/admin-console-service` | Admin console service image |
| `ADMIN_CONSOLE_SERVICE_TAG` | `latest` | Admin console service image tag |
| `ADMIN_CONSOLE_SERVICE_PORT` | `8082` | Admin console service port on your machine |
| `ADMIN_CONSOLE_SERVICE_LOCAL_IMAGE` | `admin-console-service:local` | Image used by `compose.build.yaml` |

These values are for local use only. `compose/.env` is ignored by git.

## Databases

| Database | Owner | Used by |
|---|---|---|
| `regulatory` | `regulatory_api` | [regulatory-api](https://github.com/GRaCe-GRC/regulatory-api) |

The databases and users are created the first time PostgreSQL starts
(`compose/postgres/init/`). Tables are created by each API's Flyway migrations when the API starts,
not here.

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
