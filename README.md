# Go backend service template

This repository is a starting point for production Go backend services. It
provides a standard development workflow through the included `Makefile` and a
README structure that each service can adapt.

## Use this repository

1. Create a new repository from this template.
2. Replace every `{{PLACEHOLDER}}` in this file.
3. Delete guidance comments and sections that do not apply.
4. Initialize the Go module:

   ```bash
   go mod init {{MODULE_PATH}}
   ```

5. Add the service code and update the proposed project structure below.
6. Run `make bootstrap` to install the pinned development tools.
7. Run `make check` before opening a pull request.

The rest of this file is the README template for the service created from this
repository.

---

# {{SERVICE_NAME}}

{{ONE_SENTENCE_DESCRIPTION}}

<!--
State the service's business purpose, who uses it, and what it owns. Avoid
describing implementation details here. Delete this comment when complete.
-->

## Status

{{DEVELOPMENT_STATUS}}

<!--
Examples: experimental, active development, production, or deprecated. Add CI,
coverage, release, and documentation badges only when they provide useful
information.
-->

## What this service does

{{SERVICE_RESPONSIBILITIES}}

<!--
List the capabilities this service owns. Also state important boundaries, such
as data or workflows owned by another service.
-->

## Getting started

### Prerequisites

- Go {{GO_VERSION}}
- {{EXTERNAL_DEPENDENCY_AND_VERSION}}
- `make`
- {{OTHER_REQUIRED_TOOL}}

### Run locally

1. Clone the repository:

   ```bash
   git clone {{REPOSITORY_URL}}
   cd {{REPOSITORY_DIRECTORY}}
   ```

2. Install the pinned development tools:

   ```bash
   make bootstrap
   ```

3. Create the local configuration:

   ```bash
   cp {{EXAMPLE_CONFIG_PATH}} {{LOCAL_CONFIG_PATH}}
   ```

4. Start required dependencies:

   ```bash
   {{START_DEPENDENCIES_COMMAND}}
   ```

5. Run the service:

   ```bash
   {{RUN_COMMAND}}
   ```

6. Check that it is ready:

   ```bash
   curl --fail {{HEALTH_CHECK_URL}}
   ```

The service listens on `{{LOCAL_ADDRESS}}` by default.

## Configuration

The service loads configuration from {{CONFIGURATION_SOURCES_AND_ORDER}}.

| Setting            | Required      | Default             | Description                       |
| ------------------ | ------------- | ------------------- | --------------------------------- |
| `{{SETTING_NAME}}` | {{YES_OR_NO}} | `{{DEFAULT_VALUE}}` | {{SETTING_DESCRIPTION}}           |
| `{{SECRET_NAME}}`  | Yes           | None                | {{SECRET_DESCRIPTION_AND_SOURCE}} |

<!--
Document every operator-facing setting. Never put real credentials or secret
values in this file. Explain where developers and deployed instances obtain
secrets.
-->

## API

The service exposes {{API_STYLE_AND_VERSION}}, documented at
{{API_DOCUMENTATION_LOCATION}}.

### Example request

```bash
curl --request {{HTTP_METHOD}} \
  --header 'Content-Type: application/json' \
  --data '{{REQUEST_BODY}}' \
  {{ENDPOINT_URL}}
```

### Example response

```json
{
  "{{FIELD_NAME}}": "{{FIELD_VALUE}}"
}
```

<!--
Link to the full OpenAPI, protobuf, GraphQL, or event contract. Keep one small,
working example here for the most common operation. For consumers, document
authentication, errors, pagination, rate limits, and compatibility policy.
-->

## Project structure

```text
cmd/
  {{BINARY_NAME}}/       # Process entry point and dependency assembly
config/
  {{BINARY_NAME}}/       # Checked-in, non-secret configuration
database/
  migrations/            # Schema migrations
  sqlc/                  # SQL queries and generated database code
deploy/                  # Deployment manifests
internal/                # Packages private to this module
```

{{NOTES_ABOUT_IMPORTANT_PACKAGES_OR_BOUNDARIES}}

<!--
Change this tree to match the repository. Describe boundaries that are not
obvious from directory names. Do not list every file.
-->

## Development

The Makefile is the development and CI command contract.

| Command          | Purpose                                                           |
| ---------------- | ----------------------------------------------------------------- |
| `make help`      | List available targets.                                           |
| `make bootstrap` | Install pinned development tools in `.tools/`.                    |
| `make build`     | Build all packages.                                               |
| `make test`      | Run all tests.                                                    |
| `make test-race` | Run tests with the race detector.                                 |
| `make bench`     | Run benchmarks with memory statistics.                            |
| `make fmt`       | Format Go source and imports.                                     |
| `make fmt-check` | Report formatting differences.                                    |
| `make lint`      | Run configured linters.                                           |
| `make vet`       | Run `go vet`.                                                     |
| `make generate`  | Run Go generators.                                                |
| `make tidy`      | Synchronize module dependencies.                                  |
| `make vuln`      | Scan dependencies for known vulnerabilities.                      |
| `make check`     | Run formatting, vet, lint, race, build, and vulnerability checks. |
| `make clean`     | Remove locally installed development tools.                       |

### Tests

Run the full test suite with:

```bash
make test
```

{{TEST_STRATEGY_AND_REQUIRED_TEST_DEPENDENCIES}}

<!--
Explain the split between unit, integration, and end-to-end tests. Include any
required build tags, fixtures, containers, seed data, and focused test commands.
-->

### Code generation

Run generators with:

```bash
make generate
```

{{GENERATED_FILES_AND_THEIR_SOURCES}}

<!-- Delete this section when the service has no generated code. -->

## Data and migrations

{{DATA_STORES_AND_OWNERSHIP}}

To apply migrations locally:

```bash
{{MIGRATE_UP_COMMAND}}
```

To roll back the latest migration:

```bash
{{MIGRATE_DOWN_COMMAND}}
```

<!--
Describe migration ordering, rollback policy, test data, retention, and backup
expectations. Delete this section when the service stores no data.
-->

## Observability

- Logs: {{LOG_FORMAT_LEVELS_AND_LOCATION}}
- Metrics: {{METRICS_ENDPOINT_AND_DASHBOARD}}
- Traces: {{TRACING_BACKEND_AND_LOOKUP_FIELDS}}
- Alerts: {{ALERTS_AND_RUNBOOK_LOCATION}}

<!--
Give operators enough information to answer whether the service is healthy and
to investigate a failed request. Link dashboards and runbooks where available.
-->
