FROM quay.io/fedora/fedora-toolbox:43

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    BUN_INSTALL=/opt/bun \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PATH=/opt/bun/bin:/usr/local/bin:/usr/local/sbin:/usr/bin

RUN dnf -y upgrade && \
    dnf -y install \
      bash-completion bc bind-utils bzip2 curl dbus dbus-daemon dbus-tools diffutils fd-find findutils fuse-overlayfs fzf gcc gcc-c++ git git-lfs glib2 glib2-devel glibc-langpack-en gnupg2 golang hostname iproute iputils jq keyutils krb5-libs less libX11-devel libXcursor-devel libXi-devel libXinerama-devel libXrandr-devel libXxf86vm-devel libxcrypt-compat.x86_64 libxkbcommon-devel lsof make man-db man-pages mesa-libGL-devel mtr ncurses ninja-build nmap-ncat npm openssl pam passwd pigz pinentry pipx pkgconf-pkg-config podman-compose podman-remote postgresql ripgrep rust cargo rustfmt rsync shadow-utils slirp4netns sqlite strace sudo tcpdump time traceroute tree unzip util-linux util-linux-script vte-profile wget which whois words xdg-dbus-proxy xdg-utils xorg-x11-xauth xz zip zsh \
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

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /opt/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting && \
    chmod -R go-w /opt/oh-my-zsh

RUN printf '%s\n' '\
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(dir vcs)\n\
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(status command_execution_time time)\n\
typeset -g POWERLEVEL9K_PROMPT_ON_NEWLINE=true\n\
typeset -g POWERLEVEL9K_MULTILINE_FIRST_PROMPT_PREFIX=""\n\
typeset -g POWERLEVEL9K_MULTILINE_LAST_PROMPT_PREFIX=">>> "\n\
typeset -g POWERLEVEL9K_TIME_FORMAT=%D{%H:%M:%S}\n\
typeset -g POWERLEVEL9K_MODE=compatible\n\
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY=truncate_to_unique\n\
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3\n\
typeset -g POWERLEVEL9K_VCS_MAX_INDEX_SIZE_DIRTY=-1\n\
' > /etc/p10k.zsh

RUN printf '%s\n' '\
export ZSH=/opt/oh-my-zsh\n\
export ZSH_DISABLE_COMPFIX=true\n\
export DISABLE_AUTO_TITLE=true\n\
ZSH_COMPDUMP=${XDG_CACHE_HOME:-/tmp}/zsh/.zcompdump-$HOST-$UID\n\
mkdir -p ${ZSH_COMPDUMP:h} 2>/dev/null || true\n\
autoload -Uz compinit; compinit -C -d "$ZSH_COMPDUMP"\n\
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)\n\
ZSH_THEME="powerlevel10k/powerlevel10k"\n\
source $ZSH/oh-my-zsh.sh\n\
[ -r /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh\n\
[ -r /etc/p10k.zsh ] && source /etc/p10k.zsh\n\
' > /etc/zshrc

COPY skel-zshrc /etc/skel/.zshrc
RUN chsh -s /usr/bin/zsh root || true && \
    printf 'if [ -n "$BASH_VERSION" -a -t 1 ]; then exec /usr/bin/zsh -l; fi\n' > /etc/profile.d/90-auto-zsh.sh

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
