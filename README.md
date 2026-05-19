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

Inside Distrobox, `xdg-open`, `gio`, `dbus-run-session`, `podman`, `docker`, `distrobox`, and `systemctl` call the host through `distrobox-host-exec`. This keeps browser/link opening, host containers, and host systemd commands usable from the dev shell.

Codex is installed with Bun in the image. Runtime state stays in the mounted home directory under `$HOME/.codex`.
