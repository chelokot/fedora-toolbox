# dev
my personal development container image for fedora silverblue with stuff I use

The container itself is declared and run by [`chelokot/machine`](https://github.com/chelokot/machine) as a Podman Quadlet named `dev`.

Inside the container, `xdg-open`, `gio`, `dbus-run-session`, `systemctl`, `journalctl`, `flatpak`, `rpm-ostree` and `bootc` run on the host through `host-spawn`, and `podman`/`docker` are `podman-remote` talking to the host podman socket. This keeps browser/link opening, host containers, and host systemd commands usable from the dev shell.

## Declared packages

Everything installed into the image is declared in `packages/`:

| File | Installed with |
| --- | --- |
| `packages/dnf.txt` | `dnf install` (extra repositories live in `repos/`) |
| `packages/dnf-remove.txt` | `dnf remove` of packages that come with the base image |
| `packages/pipx.txt` | `pipx install` |
| `packages/npm.txt` | `npm install -g` |
| `packages/bun.txt` | `bun add --global` |

Inside the container `dnf`, `pipx`, `npm` and `bun` are wrappers. After a successful install or removal, [`machine record`](https://github.com/chelokot/machine) updates the matching manifest in a checkout at `~/.local/share/dev`, commits and pushes to `main` in the background, so the next image build includes the change. Failures are logged to `~/.local/state/machine/record.log`. Set `MACHINE_RECORD=0` to skip recording for one command.

Images are rebuilt daily, signed with cosign (keyless, GitHub OIDC) and carry build provenance attestations:

```sh
cosign verify ghcr.io/chelokot/dev:latest \
  --certificate-identity-regexp 'https://github.com/chelokot/dev/' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
gh attestation verify oci://ghcr.io/chelokot/dev:latest --owner chelokot
```

Codex is installed with Bun in the image. Runtime state stays in the mounted home directory under `$HOME/.codex`.

Fish is the default shell. The image includes Starship, Fisher, and `chelokot/starship-show-on-command.fish`; default fish and Starship configs are copied into `/etc/skel`.

`host/dev` is the host-side `dev` command: a fish shell in the running container in the current directory, straight through `podman exec`.
