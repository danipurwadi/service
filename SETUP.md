# Project setup

> **For the agent:** this file is a one-time setup script. Follow it when the
> user asks to set up this project, or when `AGENTS.md` says the project has
> not been set up. When you finish, `AGENTS.md` and `README.md` describe this
> project and this file no longer exists.

General Go conventions live in [docs/go-conventions.md](docs/go-conventions.md).
Do not copy them into `AGENTS.md`; link to them instead.

## 1. Inspect the repository

Before asking anything, read `go.mod`, `Makefile`, `README.md`, `cmd/`,
`internal/`, and `apm.yml`, and run `git remote get-url origin`. Use what you
find to propose defaults, so the user only confirms or corrects them. For
example, derive the run command, listen address, and health check route from
`cmd/` and the HTTP handlers.

## 2. Ask the user about the project

Ask these questions, a few at a time. Offer the default you found in the
repository where one exists. Skip questions the user has already answered and
accept "not applicable" or "unknown" as answers.

1. **Name:** What is the service called?
2. **Purpose:** In one or two sentences, what does it do and who uses it?
3. **Responsibilities:** What capabilities and data does it own? What is
   explicitly owned by another service?
4. **Module path:** What Go module path should it use? (Current: the `module`
   line in `go.mod`.)
5. **Binaries:** Which executables will it have? (For example `cmd/api`,
   `cmd/worker`, `cmd/migrate`.)
6. **Interfaces:** How do clients talk to it? (For example REST, gRPC, events,
   CLI.)
7. **Data stores and external systems:** Which databases, caches, queues, and
   third-party APIs does it depend on?
8. **Deployment target:** Where does it run? (For example Kubernetes, Lambda,
   library only.)
9. **CI:** Where does CI run, and which workflow file or URL should agents
   check?
10. **Maintainers:** Which team or `CODEOWNERS` entry owns it?
11. **Project-specific rules:** Anything agents must always or never do in this
    repository that the general conventions do not cover?
12. **Status:** What is the development status? (For example experimental,
    active development, production, deprecated.)
13. **Repository URL:** What URL should the README use for cloning? (Default:
    the `origin` remote.)
14. **Local development:** Which tools besides Go and `make` are required, how
    are local dependencies started (for example `docker compose up -d`), and
    is there an example configuration file to copy?
15. **Configuration:** Which settings and secrets does the service read, which
    are required, what are their defaults, and where do developers get
    secrets?
16. **API documentation:** Where is the API contract documented (OpenAPI,
    protobuf, etc.), and what is the most common request a client makes?
17. **Data and migrations:** Which data does the service own, and which
    commands apply and roll back migrations?
18. **Testing and generation:** How are tests split between unit, integration,
    and end-to-end, and what do they need to run? Is any code generated, and
    from what?
19. **Observability:** Where do logs, metrics, traces, and alerts go, and where
    are the dashboards and runbooks?

Questions 12 to 19 only feed `README.md`. If the user wants to skip them, skip
them; step 4 explains how to handle the gaps.

Summarize the answers back to the user and get confirmation before writing
anything.

## 3. Write `AGENTS.md`

Replace the entire contents of `AGENTS.md` with the template below. Fill in
every `<placeholder>` from the user's answers. Delete lines and sections whose
answer is "not applicable", and write "Unknown" where the user did not know.
Do not leave any `<placeholder>` in the result.

````markdown
# <Name>

<Purpose, one or two sentences.>

## Project facts

- Module: `<module path>`
- Go version: `<go version from go.mod>`
- Binaries: <binaries>
- Interfaces: <interfaces>
- Data stores and external systems: <data stores and external systems>
- Deployment target: <deployment target>
- CI: <CI workflow path or URL>
- Maintainers: <team or CODEOWNERS entry>

## Responsibilities

<What this service owns, and what it explicitly does not own.>

## Project-specific rules

<Rules from question 11, as a bulleted list.>

## Conventions

Follow [docs/go-conventions.md](docs/go-conventions.md) for coding conventions,
architecture, testing, security, and delivery practices. Instructions in this
file take precedence over that document.

Use the `Makefile` targets for routine work; run `make help` to list them and
`make check` before handing work back.

Agent skills are managed by APM. They are declared in `apm.yml`, locked in
`apm.lock.yaml`, and installed into `.agents/skills/` with `apm install`.

## Commits

Always commit as the local git user configured in this repository
(`git config user.name` and `git config user.email`). Never commit as the
agent:

- Do not pass `--author`, set `GIT_AUTHOR_*` or `GIT_COMMITTER_*`, or change
  `user.name` or `user.email`.
- Do not add `Co-Authored-By` trailers or other agent attribution to commit
  messages or pull request descriptions.
````

Copy the "Commits" section exactly as written; it has no placeholders.

## 4. Write `README.md`

`README.md` starts with instructions for using this template, followed by a
`---` line and the service README template. Rewrite it so that only the
service README remains:

1. Delete everything above and including the first `---` line.
2. Replace every `{{PLACEHOLDER}}` using the answers and what you found in the
   repository. For example, fill `{{SERVICE_NAME}}` from question 1,
   `{{GO_VERSION}}` from `go.mod`, `{{REPOSITORY_URL}}` from question 13, and
   `{{HEALTH_CHECK_URL}}` from the health route in the HTTP handlers.
3. Make the "Project structure" tree match the directories that actually exist,
   plus any binaries the user listed in question 5.
4. Delete every `<!-- ... -->` guidance comment.
5. When the answer for a section is "not applicable", delete the section. For
   example, delete "Data and migrations" when the service stores no data, and
   "Code generation" when nothing is generated.
6. When the answer is "unknown", keep the heading and replace the placeholder
   with a short `TODO:` sentence that says what is missing.

Do not leave any `{{...}}` text in the result.

## 5. Apply the module path

If the user chose a module path that differs from `go.mod`, update the `module`
line in `go.mod` and every import that uses the old path. Then run `make build`
and `make test` and report the result.

## 6. Finish

1. Confirm `AGENTS.md` contains no `<placeholder>` text and no mention of
   `SETUP.md`, and that `README.md` contains no `{{...}}` text.
2. Delete this file (`SETUP.md`).
3. Tell the user what you wrote, and list any `TODO:` items left in
   `README.md`.
