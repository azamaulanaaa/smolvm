# Smol environments

This repository contains the declarative [Smolfile](https://smolmachines.com/docs/introduction/concepts/smolfile) configurations used to prepare three Linux environments:

| File | Purpose | Workload |
| --- | --- | --- |
| [`base.smolfile`](base.smolfile) | Small Debian development base with `curl`, `bash`, `git`, and `mise` | `bash` |
| [`pi.smolfile`](pi.smolfile) | Debian-based Node image with the Pi coding agent and its extensions | `pi` |
| [`opencode.smolfile`](opencode.smolfile) | Debian with OpenCode and `tini` as the process entrypoint | `opencode` |

The `.smolfile` suffix is intentional. `smolvm` accepts any path passed to
`--smolfile`/`-s`; `Smolfile` without an extension is only the conventional
name for a single default configuration.

## Requirements

`make` and `smolvm` are **not required to review or edit this repository**.
They are only required to run or package the environments on a host.

To run a Smolfile, install `smolvm` on a supported host and follow the
[local CLI documentation](https://smolmachines.com/docs/local). On Linux,
the host must expose KVM at `/dev/kvm`:

```sh
curl -fsSL https://smolmachines.com/install.sh | bash
smolvm --version
```

The installer and the runtime are external to this repository; no runtime or
build tool is vendored here.

## Run an environment

OpenCode and Pi can be run ephemerally with their checked-in configuration.
Their `[dev].init` commands provision the guest before the workload starts:

```sh
smolvm machine run --smolfile opencode.smolfile
smolvm machine run --smolfile pi.smolfile
```

For a persistent environment, use the documented lifecycle and give each
machine a unique name:

```sh
smolvm machine create --name opencode-dev --smolfile opencode.smolfile
smolvm machine start --name opencode-dev
smolvm machine exec --name opencode-dev -- opencode --version
smolvm machine stop --name opencode-dev
smolvm machine delete --name opencode-dev --force
```

`base.smolfile` is a foundation rather than an application. It can be used in
the same way, normally followed by `machine exec` commands.

The provisioning steps in `[dev].init` are part of the machine setup. When
creating a pack, preserve that installed state by creating and starting a
machine first and then packing that stopped machine, as the optional build
helper does. Do not assume that a direct `pack create --smolfile` has run the
development initialization commands.

## Optional artifact builds

The lowercase [`makefile`](makefile) is an optional convenience wrapper. On a
host that has both GNU Make and `smolvm`, it can create a stopped machine from
each Smolfile, provision it, and write a single-file launcher under `dist/`:

```sh
make                 # all discovered *.smolfile files
make opencode        # one target
make SMOLS="pi base" # a subset
make help
```

`dist/` is generated output and is intentionally ignored by Git; it is not a
source-of-truth directory and binaries are not checked in. The runtime's
[pack documentation](https://smolmachines.com/docs/local/pack-and-smolmachine-cli)
describes the launcher/sidecar and architecture rules for generated artifacts.

## Configuration notes

- `base.smolfile` and `opencode.smolfile` use `debian:stable-slim` directly.
  `pi.smolfile` uses the Debian-based `node:trixie-slim` image because Pi
  requires Node.js and npm; it is intentionally not replaced with a bare
  Debian image.
- All three configurations explicitly use one vCPU, 512 MiB of memory, and
  one-GiB storage/overlay limits. Change the values in the relevant Smolfile
  when a workload needs more room.
- `net = true` is required by the provisioning commands. The configurations
  do not use an egress allow-list, so treat them as developer environments and
  review the init commands before using them with sensitive material.
- The OpenCode and Pi setup commands install floating upstream packages. They
  are convenient development environments, not reproducible release locks.
- Keep provider credentials outside the Smolfiles. Configure them through the
  host environment or the tools' supported credential mechanisms.

Authoritative references:

- [Smolfile format](https://smolmachines.com/docs/introduction/concepts/smolfile)
- [Local lifecycle and CLI reference](https://smolmachines.com/docs/local/machine-lifecycle-cli-reference)
- [OpenCode documentation](https://opencode.ai/docs)
