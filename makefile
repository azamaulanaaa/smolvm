# pi.smolfile -> dist/pi (single-file executable via smolvm)
# Usage: make        # builds dist/pi
#        make clean  # removes dist/ + any leftover VM
#        make help   # this help

SHELL       := /bin/sh
.SHELLFLAGS := -eu -c
.DELETE_ON_ERROR:
.NOTPARALLEL:

VM       ?= pi
SMOLFILE ?= pi.smolfile
OUTPUT   ?= dist/pi

# default goal
.DEFAULT_GOAL := pi

.PHONY: pi all clean help check

all: pi

# verify tools + inputs before doing work
check:
	@command -v smolvm >/dev/null 2>&1 || { echo "error: smolvm not in PATH" >&2; exit 1; }
	@test -f "$(SMOLFILE)" || { echo "error: $(SMOLFILE) not found" >&2; exit 1; }

# rebuild when smolfile changes; output is the packed binary
pi: check $(SMOLFILE)
	@mkdir -p "$(dir $(OUTPUT))"
	@echo "==> cleaning previous VM '$(VM)' (if any)..."
	-smolvm machine rm --name "$(VM)" --force --cascade 2>/dev/null || true
	@echo "==> creating VM '$(VM)' from $(SMOLFILE)..."
	smolvm machine create --name "$(VM)" --smolfile "$(SMOLFILE)"
	@echo "==> starting VM '$(VM)'..."
	smolvm machine start --name "$(VM)"
	@echo "==> stopping VM '$(VM)'..."
	smolvm machine stop --name "$(VM)"
	@echo "==> packing VM -> $(OUTPUT)..."
	smolvm pack create --from-vm "$(VM)" --single-file --output "$(OUTPUT)"
	@echo "==> removing build VM '$(VM)'..."
	smolvm machine rm --name "$(VM)" --force --cascade
	@echo "==> built $(OUTPUT) ($$(du -h "$(OUTPUT)" | cut -f1))"

clean:
	@echo "==> cleaning..."
	-smolvm machine rm --name "$(VM)" --force --cascade 2>/dev/null || true
	rm -rf dist
	rm -f "$(OUTPUT)"
	@echo "==> clean done"

help:
	@printf '%s\n' "Targets:"
	@printf '  %-12s %s\n' "pi (default)" "Build single-file binary '$(OUTPUT)' from '$(SMOLFILE)' via smolvm"
	@printf '  %-12s %s\n' "all"          "Alias for pi"
	@printf '  %-12s %s\n' "clean"        "Remove '$(OUTPUT)' and any leftover VM '$(VM)'"
	@printf '  %-12s %s\n' "help"         "Show this help"
	@printf '\nVariables (override: make VAR=value):\n'
	@printf '  %-12s %s\n' "VM"           "VM name (default: pi)"
	@printf '  %-12s %s\n' "SMOLFILE"     "smolfile path (default: pi.smolfile)"
	@printf '  %-12s %s\n' "OUTPUT"       "output binary (default: dist/pi)"
