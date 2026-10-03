# fedora-toolbox
my personal image for personal usage on fedora silverblue with stuff I use

## Distrobox

Create the container from this repo config:

```sh
distrobox-assemble create --file distrobox.ini
```

Distrobox provides `distrobox-export` inside entered containers for exporting container apps and binaries to the host:

```sh
distrobox-export --bin /path/to/bin
distrobox-export --app app-name
```

Inside a container, `xdg-open`, `gio`, `dbus-run-session`, `systemctl`, `journalctl`, `distrobox`, `toolbox`, `flatpak`, `rpm-ostree` and `bootc` run on the host through `host-spawn`, and `podman`/`docker` are `podman-remote` talking to the host podman socket. This keeps browser/link opening, host containers, and host systemd commands usable from the dev shell.

## Declared packages

Everything installed into the image is declared in `packages/`:

| File | Installed with |
| --- | --- |
| `packages/dnf.txt` | `dnf install` (extra repositories live in `repos/`) |
| `packages/dnf-remove.txt` | `dnf remove` of packages that come with the base image |
| `packages/pipx.txt` | `pipx install` |
| `packages/npm.txt` | `npm install -g` |
| `packages/bun.txt` | `bun add --global` |

Inside the container `dnf`, `pipx`, `npm` and `bun` are wrappers. After a successful install or removal, [`machine record`](https://github.com/chelokot/machine) updates the matching manifest in a checkout at `~/.local/share/fedora-toolbox`, commits and pushes to `main` in the background, so the next image build includes the change. Failures are logged to `~/.local/state/machine/record.log`. Set `MACHINE_RECORD=0` to skip recording for one command.

Images are rebuilt daily, signed with cosign (keyless, GitHub OIDC) and carry build provenance attestations:

```sh
cosign verify ghcr.io/chelokot/fedora-toolbox:latest \
  --certificate-identity-regexp 'https://github.com/chelokot/fedora-toolbox/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
gh attestation verify oci://ghcr.io/chelokot/fedora-toolbox:latest --owner chelokot
```

Codex is installed with Bun in the image. Runtime state stays in the mounted home directory under `$HOME/.codex`.

Fish is the default shell for repo-managed Distrobox containers. The image includes Starship, Fisher, and `chelokot/starship-show-on-command.fish`; default fish and Starship configs are copied into `/etc/skel`.

For Ptyxis profiles that should open this toolbox quickly, use `host/fedora-toolbox-fast-shell` as a host-side custom command. It skips Distrobox's per-tab environment builder for already running containers and goes directly through `podman exec`.
