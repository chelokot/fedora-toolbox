FROM quay.io/fedora/fedora-toolbox:44

ARG EXPOSEDCAT_DOTFILES_REF=0b9071e95f67f67dabb917d761a4fa2948c1148e

ENV LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    BUN_INSTALL=/opt/bun \
    PIPX_HOME=/opt/pipx \
    PIPX_BIN_DIR=/usr/local/bin \
    PATH=/usr/local/bin:/usr/local/sbin:/opt/bun/bin:/usr/bin

COPY repos/ /etc/yum.repos.d/
COPY keys/ /etc/pki/rpm-gpg/
COPY packages/dnf.txt packages/dnf-remove.txt /usr/share/fedora-toolbox/packages/
RUN dnf -y upgrade && \
    sed 's/#.*//' /usr/share/fedora-toolbox/packages/dnf.txt | xargs dnf -y install && \
    sed 's/#.*//' /usr/share/fedora-toolbox/packages/dnf-remove.txt | xargs -r dnf -y remove && \
    dnf clean all && \
    KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)" && \
    curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" && \
    chmod +x /usr/local/bin/kubectl

RUN curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash && \
    HELMFILE_URL="$(curl -fsSL https://api.github.com/repos/helmfile/helmfile/releases/latest | jq -r '.assets[] | select(.name | test("linux_amd64.tar.gz$")) | .browser_download_url')" && \
    curl -fsSL "$HELMFILE_URL" -o /tmp/helmfile.tar.gz && \
    tar -xzf /tmp/helmfile.tar.gz -C /tmp helmfile && \
    install -m 0755 /tmp/helmfile /usr/local/bin/helmfile && \
    rm -f /tmp/helmfile /tmp/helmfile.tar.gz

COPY packages/pipx.txt /usr/share/fedora-toolbox/packages/
RUN sed 's/#.*//' /usr/share/fedora-toolbox/packages/pipx.txt | xargs -r -n1 pipx install && \
    pipx inject python-openstackclient python-cinderclient python-heatclient python-glanceclient

COPY packages/bun.txt packages/npm.txt /usr/share/fedora-toolbox/packages/
RUN curl -fsSL https://bun.sh/install | bash && \
    sed 's/#.*//' /usr/share/fedora-toolbox/packages/bun.txt | xargs -r bun add --global && \
    sed 's/#.*//' /usr/share/fedora-toolbox/packages/npm.txt | xargs -r npm install -g && \
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

RUN mkdir -p /etc/fish/conf.d /etc/skel/.config/fish/conf.d && \
    curl -fsSL "https://raw.githubusercontent.com/ExposedCat/dotfiles/${EXPOSEDCAT_DOTFILES_REF}/fish/colors.fish" -o /etc/fish/conf.d/10-exposedcat-colors.fish && \
    sed -i \
      -e 's/^set -Ux fish_color_command .*/set -Ux fish_color_command 7ee787/' \
      -e 's/^set -Ux fish_color_error .*/set -Ux fish_color_error ff6b81/' \
      -e 's/^set -Ux /set -g /' \
      /etc/fish/conf.d/10-exposedcat-colors.fish && \
    curl -fsSL "https://raw.githubusercontent.com/ExposedCat/dotfiles/${EXPOSEDCAT_DOTFILES_REF}/fish/config.fish" -o /tmp/exposedcat-config.fish && \
    grep -E '^[[:space:]]*set[[:space:]]+-g[[:space:]]+fish_greeting([[:space:]]|$)' /tmp/exposedcat-config.fish > /etc/fish/conf.d/00-exposedcat-greeting.fish && \
    rm -f /tmp/exposedcat-config.fish
COPY fish/config.fish /etc/skel/.config/fish/config.fish
COPY fish/conf.d/distrobox_config.fish /etc/skel/.config/fish/conf.d/distrobox_config.fish
COPY fish/fish_plugins /etc/skel/.config/fish/fish_plugins
COPY starship.toml /etc/starship.toml
COPY starship.toml /etc/skel/.config/starship.toml
RUN mkdir -p /root/.config/fish/conf.d && \
    cp /etc/skel/.config/fish/config.fish /root/.config/fish/config.fish && \
    cp /etc/skel/.config/fish/conf.d/distrobox_config.fish /root/.config/fish/conf.d/distrobox_config.fish && \
    cp /etc/skel/.config/fish/fish_plugins /root/.config/fish/fish_plugins && \
    cp /etc/skel/.config/starship.toml /root/.config/starship.toml && \
    chsh -s /usr/bin/fish root || true && \
    printf 'if [ -n "$BASH_VERSION" -a -t 1 ] && [ -z "$FEDORA_TOOLBOX_NO_AUTO_FISH" ]; then exec /usr/bin/fish -l; fi\n' > /etc/profile.d/90-auto-fish.sh

COPY --from=ghcr.io/chelokot/machine-cli:latest /machine /usr/local/bin/machine
COPY bin/record-wrapper bin/host-bridge /usr/local/libexec/fedora-toolbox/
RUN for bin in dnf pipx npm bun; do \
      ln -s ../libexec/fedora-toolbox/record-wrapper "/usr/local/bin/$bin"; \
    done && \
    for bin in xdg-open gio dbus-run-session systemctl journalctl distrobox flatpak rpm-ostree bootc toolbox; do \
      ln -s ../libexec/fedora-toolbox/host-bridge "/usr/local/bin/$bin"; \
    done && \
    ln -s /usr/bin/podman-remote /usr/local/bin/podman && \
    ln -s /usr/bin/podman-remote /usr/local/bin/docker && \
    printf 'ALL ALL=(ALL:ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/fedora-toolbox && \
    chmod 0440 /etc/sudoers.d/fedora-toolbox && \
    printf 'if [ -n "$XDG_RUNTIME_DIR" ]; then\n  export CONTAINER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\nfi\n' > /etc/profile.d/99-podman-remote.sh

COPY test/build/ /test/build/
RUN bash -x /test/build/smoke.sh

LABEL org.containers.toolbox="true"
