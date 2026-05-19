FROM quay.io/fedora/fedora-toolbox:43

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    BUN_INSTALL=/opt/bun \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PATH=/opt/bun/bin:/usr/local/bin:/usr/local/sbin:/usr/bin

RUN dnf -y upgrade && \
    dnf -y install \
      bash-completion bat bc bind-utils bzip2 curl dbus dbus-daemon dbus-tools diffutils eza fd-find ffmpeg-free findutils fish fuse-overlayfs fzf gcc gcc-c++ git git-delta git-lfs glib2 glib2-devel glibc-langpack-en gnupg2 golang gtk4-devel hostname ImageMagick iproute iputils jq just keyutils krb5-libs less libX11-devel libXcursor-devel libXi-devel libXinerama-devel libXrandr-devel libXxf86vm-devel libadwaita-devel libei-utils libxcrypt-compat.x86_64 libxkbcommon-devel lsof make man-db man-pages mesa-libGL-devel mtr ncurses ninja-build nmap-ncat npm openssl pam passwd pigz pinentry pipx pkgconf-pkg-config podman-compose podman-remote postgresql ripgrep rust cargo rustfmt rsync shadow-utils ShellCheck shfmt slirp4netns sqlite strace sudo tcpdump time traceroute tree unzip util-linux util-linux-script vte-profile vte291-gtk4-devel vulkan-loader-devel wev weston weston-demo wget which whois wl-clipboard words wtype xdg-dbus-proxy xdg-utils xdotool xorg-x11-server-Xvfb xorg-x11-xauth xz ydotool yq yt-dlp zip zsh \
      cmake clang clang-tools-extra java-21-openjdk java-21-openjdk-devel python3 python3-devel python3-pip python3.12 python3.12-devel python3-dotenv python3-lxml python3-pyyaml && \
    dnf clean all

RUN rpm --import https://rpm.releases.hashicorp.com/gpg && \
    rpm --import https://packages.microsoft.com/keys/microsoft.asc && \
    printf '[hashicorp]\nname=Hashicorp Stable - $basearch\nbaseurl=https://rpm.releases.hashicorp.com/fedora/$releasever/$basearch/stable\nenabled=1\ngpgcheck=1\ngpgkey=https://rpm.releases.hashicorp.com/gpg\n' > /etc/yum.repos.d/hashicorp.repo && \
    printf '[azure-cli]\nname=Azure CLI\nbaseurl=https://packages.microsoft.com/yumrepos/azure-cli\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc\n' > /etc/yum.repos.d/azure-cli.repo && \
    dnf -y install gh glab terraform azure-cli && \
    dnf clean all

RUN tee /etc/yum.repos.d/google-cloud-cli.repo <<'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
RUN dnf -y install google-cloud-cli && \
    dnf clean all && \
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" && \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl

RUN curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip -o /tmp/awscliv2.zip && \
    unzip -q /tmp/awscliv2.zip -d /tmp && \
    /tmp/aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli && \
    rm -rf /tmp/aws /tmp/awscliv2.zip

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    HELMFILE_URL="$(curl -fsSL https://api.github.com/repos/helmfile/helmfile/releases/latest | jq -r '.assets[] | select(.name | test("linux_amd64.tar.gz$")) | .browser_download_url')" && \
    curl -fsSL "$HELMFILE_URL" -o /tmp/helmfile.tar.gz && \
    tar -xzf /tmp/helmfile.tar.gz -C /tmp helmfile && \
    install -m 0755 /tmp/helmfile /usr/local/bin/helmfile && \
    rm -f /tmp/helmfile /tmp/helmfile.tar.gz

RUN curl -LsSf https://astral.sh/uv/install.sh | env UV_INSTALL_DIR=/usr/local/bin sh && \
    pipx install poetry && \
    pipx install ruff && \
    pipx install mypy && \
    pipx install pre-commit && \
    pipx install yamllint && \
    pipx install python-openstackclient && \
    pipx inject python-openstackclient python-cinderclient python-heatclient python-glanceclient

RUN curl -fsSL https://bun.sh/install | bash && \
    bun add --global @openai/codex && \
    npm install -g typescript ts-node corepack && \
    corepack enable && \
    curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh

RUN curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir /usr/bin && \
    mkdir -p /usr/share/fish/vendor_conf.d /usr/share/fish/vendor_functions.d /usr/share/fish/vendor_completions.d && \
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish -o /usr/share/fish/vendor_functions.d/fisher.fish && \
    curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/completions/fisher.fish -o /usr/share/fish/vendor_completions.d/fisher.fish && \
    git clone --depth=1 https://github.com/chelokot/starship-show-on-command.fish.git /tmp/starship-show-on-command.fish && \
    cp /tmp/starship-show-on-command.fish/conf.d/*.fish /usr/share/fish/vendor_conf.d/ && \
    cp /tmp/starship-show-on-command.fish/functions/*.fish /usr/share/fish/vendor_functions.d/ && \
    rm -rf /tmp/starship-show-on-command.fish

RUN mkdir -p /etc/skel/.config/fish
COPY fish/config.fish /etc/skel/.config/fish/config.fish
COPY fish/fish_plugins /etc/skel/.config/fish/fish_plugins
COPY starship.toml /etc/starship.toml
COPY starship.toml /etc/skel/.config/starship.toml
RUN mkdir -p /root/.config/fish && \
    cp /etc/skel/.config/fish/config.fish /root/.config/fish/config.fish && \
    cp /etc/skel/.config/fish/fish_plugins /root/.config/fish/fish_plugins && \
    cp /etc/skel/.config/starship.toml /root/.config/starship.toml && \
    chsh -s /usr/bin/fish root || true && \
    printf 'if [ -n "$BASH_VERSION" -a -t 1 ] && [ -z "$FEDORA_TOOLBOX_NO_AUTO_FISH" ]; then exec /usr/bin/fish -l; fi\n' > /etc/profile.d/90-auto-fish.sh

RUN for bin in xdg-open gio dbus-run-session systemctl distrobox; do \
      printf '#!/usr/bin/env sh\nif [ -n "${DISTROBOX_ENTER_PATH:-}" ] && command -v distrobox-host-exec >/dev/null 2>&1; then exec distrobox-host-exec %s "$@"; fi\nexec /usr/bin/%s "$@"\n' "$bin" "$bin" > "/usr/local/bin/$bin"; \
    done && \
    printf '#!/usr/bin/env sh\nif [ -n "${DISTROBOX_ENTER_PATH:-}" ] && command -v distrobox-host-exec >/dev/null 2>&1; then exec distrobox-host-exec podman "$@"; fi\nexec /usr/bin/podman-remote "$@"\n' > /usr/local/bin/podman && \
    printf '#!/usr/bin/env sh\nif [ -n "${DISTROBOX_ENTER_PATH:-}" ] && command -v distrobox-host-exec >/dev/null 2>&1; then exec distrobox-host-exec docker "$@"; fi\nexec /usr/bin/podman-remote "$@"\n' > /usr/local/bin/docker && \
    chmod +x /usr/local/bin/xdg-open /usr/local/bin/gio /usr/local/bin/dbus-run-session /usr/local/bin/systemctl /usr/local/bin/distrobox /usr/local/bin/podman /usr/local/bin/docker && \
    printf 'if [ -n "$XDG_RUNTIME_DIR" ]; then\n  export CONTAINER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\nfi\n' > /etc/profile.d/99-podman-remote.sh

COPY test/build/smoke.sh /test/build/smoke.sh
RUN bash -x /test/build/smoke.sh

LABEL org.containers.toolbox="true"
