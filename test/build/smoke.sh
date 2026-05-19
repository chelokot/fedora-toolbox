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
  distrobox
  docker
  fd
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
  jq
  kubectl
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
  sqlite3
  systemctl
  terraform
  ts-node
  tsc
  uv
  xdg-open
  yamllint
  zsh
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
gh --version
glab --version
gcloud --version
go version
helm version --short
helmfile version
kubectl version --client=true
node --version
npm --version
openstack --version
poetry --version
python3 --version
python3.12 --version
rustc --version
terraform version
ts-node --version
tsc --version
uv --version

if [ -n "${DISTROBOX_ENTER_PATH:-}" ]; then
  command -v distrobox-export >/dev/null
fi

test ! -d /root/.config/gcloud/legacy_credentials
test ! -e /run/secrets/gcp_key.json
test ! -d /opt/ComfyUI
! command -v ollama >/dev/null

echo "basic toolbox tools work"
