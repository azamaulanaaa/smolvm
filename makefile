# smolfile -> dist/* (single-file executable via smolvm)
# Usage: make            # builds all dist/* (default)
#        make pi         # builds dist/pi from pi.smolfile
#        make base       # builds dist/base from base.smolfile
#        make opencode   # builds dist/opencode from opencode.smolfile
#        make SMOLS="pi base"   # build only a subset
#        make clean      # removes dist/ + any leftover VMs
#        make help       # this help
#
# Adding a new smolfile: just drop <name>.smolfile next to this
# makefile — target <name> and output dist/<name> are generated
# automatically by the SMOLVM_rule macro below. No edits needed.

SHELL       := /bin/sh
.SHELLFLAGS := -eu -c
.DELETE_ON_ERROR:
.NOTPARALLEL:

# Every <name>.smolfile in this dir becomes a buildable target.
# Override on the CLI to build a subset: make SMOLS="pi base"
SMOLS ?= $(sort $(basename $(wildcard *.smolfile)))
DIST  := $(addprefix dist/,$(SMOLS))

# smolvm is NOT available in Alpine apk or npm registries.
# It has no public distribution (no smolvm.io, no GitHub release).
# The existing dist/pi was pre-built elsewhere. To rebuild locally you
# must obtain smolvm binary manually, or install opencode directly:
#   npm install -g opencode-ai  /  curl -fsSL https://opencode.ai/install | bash

# default goal
.DEFAULT_GOAL := all

.PHONY: all clean help check $(SMOLS)

all: $(DIST)

# verify smolvm binary before doing work.
# (Missing smolfiles are caught by make itself via the explicit
# dist/<name>: <name>.smolfile prerequisite below.)
check:
	@command -v smolvm >/dev/null 2>&1 || { \
		echo "error: smolvm not in PATH" >&2; \
		echo "" >&2; \
		echo "Research: smolvm has no public install (apk search finds nothing," >&2; \
		echo "smolvm.io NXDOMAIN, github.com/smolvm 404, npm has no smolvm)." >&2; \
		echo "The checked-in dist/pi is a pre-built artifact; you cannot rebuild" >&2; \
		echo "smolfiles without a smolvm binary." >&2; \
		echo "" >&2; \
		echo "Without smolvm, install directly:" >&2; \
		echo "  npm install -g opencode-ai" >&2; \
		echo "  curl -fsSL https://opencode.ai/install | bash" >&2; \
		exit 1; \
	}

# -------------------------------------------------------------------
# "Rust macro" for smolvm builds: $(call SMOLVM_rule,<name>) stamps out
#   - a real file target  dist/<name>  (incremental: rebuilds only when
#     <name>.smolfile changes)
#   - a phony shorthand   <name>       (e.g. `make pi` == `make dist/pi`)
# Add a new case by adding a new call — the foreach loop below already
# calls it once per entry in $(SMOLS), so new *.smolfile files work
# with zero makefile edits.
# -------------------------------------------------------------------
define SMOLVM_rule
dist/$(1): $(1).smolfile | check
	@mkdir -p "$$(dir $$@)"
	@echo "==> cleaning previous VM '$(1)' (if any)..."
	-smolvm machine rm --name "$(1)" --force --cascade 2>/dev/null || true
	@echo "==> creating VM '$(1)' from $$<..."
	smolvm machine create --name "$(1)" --smolfile "$$<"
	@echo "==> starting VM '$(1)'..."
	smolvm machine start --name "$(1)"
	@echo "==> stopping VM '$(1)'..."
	smolvm machine stop --name "$(1)"
	@echo "==> packing VM -> $$@..."
	smolvm pack create --from-vm "$(1)" --single-file --output "$$@"
	@echo "==> removing build VM '$(1)'..."
	smolvm machine rm --name "$(1)" --force --cascade
	@echo "==> built $$@ ($$(du -h "$$@" | cut -f1))"

.PHONY: $(1)
$(1): dist/$(1)
endef

$(foreach s,$(SMOLS),$(eval $(call SMOLVM_rule,$(s))))

clean:
	@echo "==> cleaning..."
	@for vm in $(SMOLS); do \
		smolvm machine rm --name "$$vm" --force --cascade 2>/dev/null || true; \
	done
	rm -rf dist
	@echo "==> clean done"

help:
	@printf '%s\n' "Targets:"
	@printf '  %-12s %s\n' "all (default)" "Build all: $(DIST)"
	@for s in $(SMOLS); do \
		printf '  %-12s Build single-file binary dist/%s from %s.smolfile via smolvm\n' "$$s" "$$s" "$$s"; \
	done
	@printf '  %-12s %s\n' "clean" "Remove dist and any leftover VMs ($(SMOLS))"
	@printf '  %-12s %s\n' "help"  "Show this help"
	@printf '\nVariables (override: make VAR=value):\n'
	@printf '  %-12s %s\n' "SMOLS" "space-separated smol names (default: $(SMOLS))"
