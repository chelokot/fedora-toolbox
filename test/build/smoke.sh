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
  deno
  docker
  fd
  fzf
  gcc
  gh
  git
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

test ! -d /root/.config/gcloud/legacy_credentials
test ! -e /run/secrets/gcp_key.json
test ! -d /opt/ComfyUI
! command -v ollama >/dev/null

echo "basic toolbox tools work"
