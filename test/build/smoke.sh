#!/usr/bin/env bash
set -euo pipefail

required_bins=(
  aws
  az
  bun
  cargo
  cmake
  codex
  curl
  dbus-run-session
  deno
  delta
  distrobox
  docker
  eza
  fd
  ffmpeg
  ffprobe
  fish
  fzf
  gcc
  gh
  git
  gio
  glab
  gcloud
  go
  helm
  helmfile
  ei-debug-events
  jq
  just
  kubectl
  magick
  make
  mypy
  node
  npm
  openstack
  podman
  poetry
  pre-commit
  psql
  python3
  python3.12
  rg
  ruff
  shellcheck
  shfmt
  sqlite3
  starship
  systemctl
  terraform
  ts-node
  tsc
  uv
  wev
  weston
  wl-copy
  wl-paste
  wtype
  xdg-open
  yamllint
  yq
  yt-dlp
  ydotool
)

for bin in "${required_bins[@]}"; do
  command -v "$bin" >/dev/null
done

distrobox_deps=(
  bc
  bzip2
  chpasswd
  curl
  diff
  find
  findmnt
  gpg
  hostname
  less
  lsof
  man
  mount
  passwd
  pigz
  pinentry
  ping
  ps
  rsync
  script
  ssh
  sudo
  time
  tree
  umount
  unzip
  useradd
  wc
  wget
  xauth
  zip
)

for dep in "${distrobox_deps[@]}"; do
  command -v "$dep" >/dev/null
done

host_bridges=(
  dbus-run-session
  distrobox
  docker
  gio
  podman
  systemctl
  xdg-open
)

for bridge in "${host_bridges[@]}"; do
  path="$(command -v "$bridge")"
  test "${path#/usr/local/bin/}" != "$path"
  grep -q "distrobox-host-exec $bridge" "$path"
done

aws --version
az version --output none
bun --version
codex --version
deno --version
delta --version
eza --version
ffmpeg -version >/dev/null
ffprobe -version >/dev/null
fish --version
gh --version
glab --version
gcloud --version
go version
helm version --short
helmfile --version
just --version
kubectl version --client=true
magick -version
node --version
npm --version
openstack --version
poetry --version
python3 --version
python3.12 --version
rustc --version
shellcheck --version
shfmt --version
starship --version
terraform version
ts-node --version
tsc --version
uv --version
yq --version
yt-dlp --version
fish -lc "functions -q fisher; functions -q starship-soc; test -r /etc/starship.toml; test -r /etc/skel/.config/fish/config.fish; test -r /etc/skel/.config/fish/fish_plugins; test -r /etc/fish/conf.d/00-exposedcat-greeting.fish; test -r /etc/fish/conf.d/10-exposedcat-colors.fish; test -r /etc/skel/.config/starship.toml; test \"\$fish_greeting\" = \"\"; test \"\$fish_color_command\" = 7ee787; test \"\$fish_color_error\" = ff6b81"

if [ -n "${DISTROBOX_ENTER_PATH:-}" ]; then
  command -v distrobox-export >/dev/null
fi

test ! -d /root/.config/gcloud/legacy_credentials
test ! -e /run/secrets/gcp_key.json
test ! -d /opt/ComfyUI
if command -v ollama >/dev/null; then
  exit 1
fi
if command -v zsh >/dev/null; then
  exit 1
fi

echo "basic toolbox tools work"
