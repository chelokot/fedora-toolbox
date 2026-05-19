FROM registry.fedoraproject.org/fedora-toolbox:42

RUN dnf -y upgrade && dnf -y install zsh make git podman fuse-overlayfs slirp4netns golang npm pnpm ripgrep fzf curl jq libxcrypt-compat.x86_64 openssl1.1 openssl postgresql rust cargo pkgconf-pkg-config libX11-devel libXcursor-devel libXrandr-devel libXi-devel libXinerama-devel libXxf86vm-devel mesa-libGL-devel libxkbcommon-devel wayland-devel && dnf clean all
RUN dnf -y install 'dnf-command(config-manager)' && dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo && dnf -y install gh && dnf clean all

RUN tee /etc/yum.repos.d/google-cloud-cli.repo <<'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

RUN dnf -y install google-cloud-cli && dnf clean all

RUN npm install -g typescript ts-node

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /opt/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting

# Locale + UTF-8 for clean glyphs (no host changes)
RUN dnf -y install glibc-langpack-en && dnf clean all
ENV LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

# Fix compaudit perms on shared theme dir
RUN chmod -R go-w /opt/oh-my-zsh

# Global, ASCII-only Powerlevel10k config (no Nerd Font required)
RUN printf '%s\n' '\
# Minimal fast Powerlevel10k (ASCII)\n\
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

# Global zshrc so config applies regardless of host $HOME bind mount
RUN printf '%s\n' '\
export ZSH=/opt/oh-my-zsh\n\
export ZSH_DISABLE_COMPFIX=true\n\
export DISABLE_AUTO_TITLE=true\n\
# Completion cache in /tmp to avoid host perms weirdness\n\
ZSH_COMPDUMP=${XDG_CACHE_HOME:-/tmp}/zsh/.zcompdump-$HOST-$UID\n\
mkdir -p ${ZSH_COMPDUMP:h} 2>/dev/null || true\n\
autoload -Uz compinit; compinit -C -d "$ZSH_COMPDUMP"\n\
# Plugins (syntax-highlighting must be last)\n\
plugins=(git fzf zsh-autosuggestions zsh-syntax-highlighting)\n\
ZSH_THEME=\"powerlevel10k/powerlevel10k\"\n\
source $ZSH/oh-my-zsh.sh\n\
[ -r /usr/share/fzf/shell/key-bindings.zsh ] && source /usr/share/fzf/shell/key-bindings.zsh\n\
[ -r /etc/p10k.zsh ] && source /etc/p10k.zsh\n\
' > /etc/zshrc

COPY skel-zshrc /etc/skel/.zshrc
RUN chsh -s /usr/bin/zsh root || true
RUN printf 'if [ -n "$BASH_VERSION" -a -t 1 ]; then exec /usr/bin/zsh -l; fi\n' > /etc/profile.d/90-auto-zsh.sh

RUN dnf -y install podman-remote && dnf clean all
RUN printf '#!/usr/bin/env sh\nexec /usr/bin/podman-remote "$@"\n' > /usr/bin/podman && chmod +x /usr/bin/podman && ln -sf /usr/bin/podman-remote /usr/bin/docker
RUN printf '\
if [ -n "$XDG_RUNTIME_DIR" ]; then\n\
  export CONTAINER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n\
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n\
fi\n' > /etc/profile.d/99-podman-remote.sh

RUN dnf -y install gcc-c++ make cmake pkgconfig && dnf clean all

RUN dnf -y install python3.12 python3.12-devel python3-pip \
 && dnf clean all

# COPY test/build/smoke.sh /test/build/smoke.sh
# RUN bash -x /test/build/smoke.sh

LABEL org.containers.toolbox="true"
