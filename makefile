# smolfile -> dist/* (single-file executable via smolvm)
# Usage: make          # builds dist/pi (default)
#        make opencode # builds dist/opencode from opencode.smolfile
#        make clean    # removes dist/ + any leftover VM
#        make help     # this help

SHELL       := /bin/sh
.SHELLFLAGS := -eu -c
.DELETE_ON_ERROR:
.NOTPARALLEL:

VM       ?= pi
SMOLFILE ?= pi.smolfile
OUTPUT   ?= dist/pi

# smolvm is NOT available in Alpine apk or npm registries.
# It has no public distribution (no smolvm.io, no GitHub release).
# The existing dist/pi was pre-built elsewhere. To rebuild locally you
# must obtain smolvm binary manually, or install opencode directly:
#   npm install -g opencode-ai  /  curl -fsSL https://opencode.ai/install | bash

# default goal
.DEFAULT_GOAL := pi

.PHONY: pi all clean help check opencode

all: pi

# verify tools + inputs before doing work
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

# Build opencode single-file via smolvm (requires smolvm)
opencode: VM := opencode
opencode: SMOLFILE := opencode.smolfile
opencode: OUTPUT := dist/opencode
opencode: check $(SMOLFILE)
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
	-smolvm machine rm --name opencode --force --cascade 2>/dev/null || true
	rm -rf dist
	rm -f "$(OUTPUT)"
	@echo "==> clean done"

help:
	@printf '%s\n' "Targets:"
	@printf '  %-12s %s\n' "pi (default)" "Build single-file binary 'dist/pi' from 'pi.smolfile' via smolvm"
	@printf '  %-12s %s\n' "opencode" "Build single-file binary 'dist/opencode' from 'opencode.smolfile' via smolvm"
	@printf '  %-12s %s\n' "all"          "Alias for pi"
	@printf '  %-12s %s\n' "clean"        "Remove dist and any leftover VMs"
	@printf '  %-12s %s\n' "help"         "Show this help"
	@printf '\nVariables (override: make VAR=value):\n'
	@printf '  %-12s %s\n' "VM"           "VM name (default: pi)"
	@printf '  %-12s %s\n' "SMOLFILE"     "smolfile path (default: pi.smolfile)"
	@printf '  %-12s %s\n' "OUTPUT"       "output binary (default: dist/pi)"
