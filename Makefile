SHELL := /bin/sh

.DEFAULT_GOAL := help
.DELETE_ON_ERROR:

GO ?= go
PACKAGES ?= ./...
TOOLS_DIR ?= $(CURDIR)/.tools
TOOLS_BIN := $(TOOLS_DIR)/bin

GOLANGCI_LINT := $(TOOLS_BIN)/golangci-lint
GOVULNCHECK := $(TOOLS_BIN)/govulncheck

GOLANGCI_LINT_VERSION ?= v2.5.0
GOVULNCHECK_VERSION ?= v1.1.4

.PHONY: help bootstrap build test test-race bench fmt fmt-check lint vet generate tidy vuln check clean require-module

help: ## Show available targets.
	@awk 'BEGIN {FS = ":.*##"; printf "Usage: make <target>\n\nTargets:\n"} /^[a-zA-Z0-9_-]+:.*##/ {printf "  %-14s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

bootstrap: $(GOLANGCI_LINT) $(GOVULNCHECK) ## Install pinned development tools locally.

build: require-module ## Build all packages.
	$(GO) build $(PACKAGES)

test: require-module ## Run all tests.
	$(GO) test $(PACKAGES)

test-race: require-module ## Run all tests with the race detector.
	$(GO) test -race $(PACKAGES)

bench: require-module ## Run all benchmarks with memory statistics.
	$(GO) test -run='^$$' -bench=. -benchmem $(PACKAGES)

fmt: require-module $(GOLANGCI_LINT) ## Format Go source and imports.
	$(GOLANGCI_LINT) fmt

fmt-check: require-module $(GOLANGCI_LINT) ## Report formatting differences without changing files.
	$(GOLANGCI_LINT) fmt --diff

lint: require-module $(GOLANGCI_LINT) ## Run the configured linters.
	$(GOLANGCI_LINT) run $(PACKAGES)

vet: require-module ## Run go vet on all packages.
	$(GO) vet $(PACKAGES)

generate: require-module ## Run all Go generators.
	$(GO) generate $(PACKAGES)

tidy: require-module ## Synchronize module dependencies.
	$(GO) mod tidy

vuln: require-module $(GOVULNCHECK) ## Scan dependencies for known vulnerabilities.
	$(GOVULNCHECK) $(PACKAGES)

check: fmt-check vet lint test-race build vuln ## Run all non-mutating quality checks.

clean: ## Remove locally installed development tools.
	rm -rf $(TOOLS_DIR)

require-module:
	@test -f go.mod || { printf '%s\n' 'error: go.mod not found; run "go mod init <module-path>" first' >&2; exit 1; }

$(GOLANGCI_LINT):
	@mkdir -p $(TOOLS_BIN)
	GOBIN=$(TOOLS_BIN) $(GO) install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)

$(GOVULNCHECK):
	@mkdir -p $(TOOLS_BIN)
	GOBIN=$(TOOLS_BIN) $(GO) install golang.org/x/vuln/cmd/govulncheck@$(GOVULNCHECK_VERSION)
