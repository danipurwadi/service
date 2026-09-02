# Template for AGENTS.md

> Replace every `<placeholder>` before adopting this file. Delete sections that
> do not apply. Commands and repository-specific instructions in this file take
> precedence over general Go conventions.

This template adapts the practices in the
[golang-ref-guide](https://github.com/vincentserpoul/golang-ref-guide). It also
follows the Go Code Review Comments, the Google and Uber Go style guides, and
OWASP's Go secure coding guidance referenced there.

## Project facts

- Module: `<module path from go.mod>`
- Supported Go version: `<version from go.mod or toolchain directive>`
- Service or library purpose: `<one sentence>`
- Primary binaries: `<for example: cmd/api, cmd/migrate, cmd/worker>`
- Deployment target: `<for example: Kubernetes, Lambda, library only>`
- CI workflow: `<path or URL>`
- Maintainers: `<team or CODEOWNERS entry>`

## Start here

Before changing code:

1. Read `go.mod`, the nearest package documentation, and the tests beside the
   code you will change.
2. Find the existing command, package, or interface that owns the behavior.
   Extend it instead of creating a parallel implementation.
3. Check the repository's `Makefile` or `Taskfile.yml` for the canonical
   commands. Use those targets instead of invoking `go` or other tools directly.
   If neither file exists, warn the user and identify the direct commands you
   will use as a fallback.
4. Keep the change scoped. Do not reformat, rename, or reorganize unrelated
   code.

## Repository layout

Use the layout already present in the repository. For a new service, prefer:

```text
cmd/
	api/main.go             # one directory per executable
	migrate/main.go
config/<binary>/          # base and environment-specific configuration
database/
	init/
	migrations/
	sqlc/
	testdata/
deploy/                   # container and deployment manifests
internal/                 # code private to this module
```

Keep `main` packages small. They should parse configuration, assemble
dependencies, start the process, and handle shutdown. Put business behavior in
focused packages under `internal/` or in public packages when this is a library.

Do not create `pkg/`, `util`, `common`, or `helpers` packages as dumping
grounds. Name packages for the capability they own.

## Canonical commands

The repository must expose routine development commands through a `Makefile` or
`Taskfile.yml`. These targets are the project contract for local development and
CI because they keep flags, build tags, tool versions, and setup consistent.

Replace these examples with the repository's actual targets:

```bash
make bootstrap
make build
make test
make test-race
make bench
make fmt
make lint
make vet
make generate
make check
```

For a Task-based project, use the equivalent `task <target>` commands. Inspect
available targets with `make help`, `make -n <target>`, or `task --list` before
guessing target names.

Do not bypass an existing target with direct `go`, formatter, linter, generator,
or migration commands. Direct tool invocation is acceptable for a narrow
diagnostic check when no suitable target exists. State that exception in the
handoff.

If the repository has neither a `Makefile` nor a `Taskfile.yml`, warn the user
before running direct commands. Recommend adding one and list the missing
targets needed to reproduce build, format, test, race, lint, vet, benchmark, and
generation checks. Do not silently treat ad hoc shell commands as canonical.

Run the narrowest relevant test while developing, then run the full required
checks before handing work back. Do not claim a check passed unless you ran it.

When dependencies change, use the repository's dependency or tidy target and
include the resulting `go.mod` and `go.sum` changes. If no target exists,
explain the gap before using `go mod tidy`. Do not run `go get ...@latest`
unless the task explicitly calls for an upgrade. Pin tool versions in CI or the
repository's tool manifest.

## Go style

- Format all Go code with `gofumpt`; use `gci` for deterministic import groups.
- Treat the repository's `.golangci.*` file as the linting contract. Do not
  suppress a linter without a short, specific reason.
- Prefer the standard library. Add a dependency only when it removes substantial
  code or provides a well-tested implementation of a difficult concern.
- Write idiomatic, direct Go. Favor small functions and early returns.
- Accept interfaces and return concrete types. Define an interface where the
  consumer needs substitution, usually beside that consumer.
- Keep interfaces small. Do not introduce one solely to mock a concrete type.
- Pass `context.Context` as the first parameter for request-scoped work. Never
  store a context in a struct or replace one with `context.Background()` in the
  middle of a call chain.
- Do not use package globals for mutable state, clients, databases, loggers, or
  configuration. Construct dependencies explicitly.
- Avoid `init` unless registration cannot be expressed explicitly.
- Add exported documentation where the public API needs it. Comments should
  explain intent or constraints, not restate the code.
- Use generics only after concrete duplication exists and the type parameter
  makes the implementation clearer.

## Architecture

Model the business problem before choosing transport or storage details. Use the
business vocabulary in package names, types, methods, tests, and errors.

Keep domain types and behavior independent of HTTP, SQL, queues, and vendor
SDKs. Dependencies should point toward the domain. Adapt external systems at
package boundaries.

Separate commands that change state from queries that read state when they have
different models or access patterns. Do not force CQRS into simple CRUD code.

Hide persistence behind a repository only when the abstraction belongs to the
domain and improves testing or replacement. Design it so an in-memory
implementation is possible. Define transaction ownership explicitly rather than
hiding transactions across repository calls.

Treat event sourcing as a storage implementation, not a default architecture.
Events describe facts that already happened and use past-tense names. Commands
describe requested actions.

## HTTP APIs

- Build servers and handlers on `net/http` contracts. A router or middleware
  must remain compatible with `http.Handler`.
- Prefer `chi` when this project needs a router and has not chosen one already.
- Use nouns for resources and HTTP methods for actions. Do not put verbs in
  resource paths without a domain-specific reason.
- Put the major API version in the URL when response contracts can diverge.
- Configure read, header, write, and idle timeouts. Limit request body sizes.
- Support graceful shutdown and allow in-flight requests a bounded time to end.
- Inject handler dependencies. Do not reach into global state.
- Centralize JSON decoding, encoding, and error responses so status codes and
  response shapes remain consistent.
- Validate untrusted input at the transport boundary. Do not expose internal
  errors, credentials, SQL text, or stack traces to clients.
- Propagate trace context on inbound and outbound requests.

## Configuration and secrets

Use one typed configuration struct per binary and validate it once at startup.
When starting a new configuration implementation, prefer `koanf` over a global,
stateful configuration package.

Load configuration in this order, with later layers overriding earlier ones:

1. `config/<binary>/base.toml` for checked-in defaults.
2. `config/<binary>/<environment>.toml` for checked-in environment values.
3. Environment variables for per-instance values.
4. A mounted, ignored secrets file for credentials and other secrets.

Use `__` as the environment-variable nesting separator, for example `LOG__LEVEL`
maps to `log.level`. Never commit secrets. Do not log complete configuration
structs because they may contain secret values.

## Errors

- Handle every error once. Return it, translate it at a boundary, or log it at
  the process edge. Do not both log and return the same error without a reason.
- Add concise operation context with `%w`, for example
  `fmt.Errorf("load account %q: %w", id, err)`.
- Use `errors.Is` for sentinel comparisons and `errors.As` for typed errors. Use
  `errors.AsType` only when the module's Go version supports it.
- Use typed errors for public API failures callers need to inspect.
- Wrapping exposes the wrapped error as part of the API. Translate internal
  errors at public boundaries when callers should not depend on them.
- Use `errors.Join` when several independent cleanup operations can fail.
- Do not panic for expected failures or invalid user input. A library may panic
  only for a documented programmer error or an impossible invariant.
- Keep error messages lowercase, concise, and without trailing punctuation.

## Concurrency

Prefer straightforward synchronous code until measurements or requirements show
that concurrency is needed. Horizontal scaling is often simpler than complex
in-process coordination.

- Every goroutine must have an owner, a cancellation path, and a defined end.
- Bound worker counts, queues, retries, and fan-out. Never create unbounded
  goroutines from request or message input.
- Propagate cancellation and deadlines through context.
- Make channel ownership clear. The sender closes a channel; receivers do not.
- Protect shared state deliberately and document the invariant guarded by a
  mutex or atomic operation.
- Test concurrent code with `go test -race` and, where appropriate,
  `go.uber.org/goleak`.

## Data and external systems

Follow existing project choices first. For a new implementation without an
established dependency:

- PostgreSQL: use `pgx`. Prefer SQL and `sqlc` over an ORM. Use `golang-migrate`
  for migrations.
- Database tests: use Testcontainers so tests own their dependencies and
  cleanup.
- Redis: use `go-redis`, which manages its connection pool.
- Kafka: use `kafka-go`.
- UUIDs: use `github.com/google/uuid`; do not use `satori/go.uuid`.
- Money: never use binary floating point. Prefer `cockroachdb/apd/v3`, pass an
  explicit decimal context, and define precision and rounding rules. Serialize
  decimal values as strings when clients may parse JSON numbers as IEEE-754.

Keep SQL and vendor types out of domain types. Repositories or adapters
translate between persistence models and domain models. Make transaction
boundaries visible to the application service that owns the operation.

## Logging and observability

- Use structured logging with `log/slog` unless the project already has a
  compatible logging abstraction.
- Pass loggers explicitly or derive request-scoped loggers at the boundary.
- Use stable field names. Include useful identifiers such as request, trace, and
  entity IDs, but never credentials, tokens, full payment data, or personal
  data.
- Emit one useful log at the boundary where an error is handled. Avoid noisy
  entry and exit logs.
- Use the official OpenTelemetry Go libraries for traces and metrics.
- Instrument inbound and outbound HTTP with OpenTelemetry-compatible middleware,
  including `otelhttp` for clients.
- Preserve propagation headers across service calls and shut down telemetry
  providers so buffered data can flush.
- Profile before optimizing. Keep benchmark results when performance is part of
  a release contract.

## Testing

- Put tests beside the package they exercise and prefer table-driven tests when
  cases share setup and assertions.
- Use the standard `testing` package by default. Add assertion libraries only if
  the repository has already standardized on one.
- Test observable behavior, boundary failures, and cancellation. Avoid tests
  coupled to private implementation details.
- Prefer an in-memory repository implementation over mocks for domain storage.
  Mock external dependencies only.
- When a generated mock is warranted, prefer `matryer/moq` and commit the
  `go:generate` directive. Use `uber-go/mock` only when ordered or strict call
  expectations matter.
- Add fuzz tests for parsers, codecs, validation, and other functions with broad
  input spaces.
- Add benchmarks for performance-sensitive code. Report measurements before and
  after an optimization.
- Keep end-to-end tests focused on wiring and critical journeys. Exercise most
  behavior at package and integration levels.

For a bug fix, first add or identify a test that fails for the reported
behavior. For a behavior change, cover the success path and meaningful failure
paths.

## Security

- Validate all external input and use parameterized SQL. Never build SQL from
  untrusted strings.
- Apply least privilege to database users, cloud identities, files, and network
  access.
- Set request, response, and collection size limits where input can be attacker
  controlled.
- Use bounded retries with backoff and jitter. Retry only idempotent operations
  unless the operation has an idempotency mechanism.
- Use `crypto/rand` for security-sensitive randomness and `crypto/subtle` when
  constant-time comparison is required.
- Run the repository's security scanner. Use `govulncheck ./...` when no project
  command exists, and scan container images with the project's configured tool.
- Do not weaken validation, authentication, TLS, lint, or security checks to
  make a test pass.

## Delivery and review

Before finishing a change:

1. Format changed Go files and imports.
2. Run focused tests for the changed packages.
3. Run the repository's `Makefile` or `Taskfile.yml` targets for test, race,
   lint, vet, build, and generation checks. Warn the user if no task runner file
   exists or a required target is missing.
4. Confirm generated files are current and no secret or local configuration was
   added.
5. Review the diff for accidental API changes, dependency additions, broad
   refactors, and unrelated formatting.
6. Update package docs, API docs, migrations, configuration examples, and
   release notes when behavior or operator responsibilities changed.

In the final handoff, summarize the behavior changed, name the checks run, and
state any remaining risk or check that could not run.
