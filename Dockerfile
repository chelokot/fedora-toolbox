FROM registry.fedoraproject.org/fedora-toolbox:42

RUN dnf -y upgrade && dnf -y install zsh make git podman fuse-overlayfs slirp4netns golang npm pnpm ripgrep fzf curl jq libxcrypt-compat.x86_64

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

RUN --mount=type=secret,id=GCP_KEY_JSON,target=/run/secrets/gcp_key.json gcloud auth activate-service-account --key-file=/run/secrets/gcp_key.json --quiet

RUN npm install -g typescript ts-node

RUN git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git /opt/oh-my-zsh && \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git /opt/oh-my-zsh/custom/themes/powerlevel10k && \
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git /opt/oh-my-zsh/custom/plugins/zsh-autosuggestions && \
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git /opt/oh-my-zsh/custom/plugins/zsh-syntax-highlighting

COPY skel-zshrc /etc/skel/.zshrc
RUN chsh -s /usr/bin/zsh root || true
RUN printf 'if [ -n "$BASH_VERSION" -a -t 1 ]; then exec /usr/bin/zsh -l; fi\n' > /etc/profile.d/90-auto-zsh.sh

RUN dnf -y install podman-remote
RUN printf '#!/usr/bin/env sh\nexec /usr/bin/podman-remote "$@"\n' > /usr/bin/podman && chmod +x /usr/bin/podman && ln -sf /usr/bin/podman-remote /usr/bin/docker
RUN printf '\
if [ -n "$XDG_RUNTIME_DIR" ]; then\n\
  export CONTAINER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n\
  export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"\n\
fi\n' > /etc/profile.d/99-podman-remote.sh

RUN NOVA_URL=$(curl -sS https://api.github.com/repos/ExposedCat/nova/releases/latest | jq -r '.assets[] | select(.name|test("linux-x64$")) | .browser_download_url') && \
    curl -sSL "$NOVA_URL" -o /usr/local/bin/nova && chmod +x /usr/local/bin/nova

ENV PATH="/usr/local/bin:/usr/local/sbin:${PATH}"
RUN curl -fsSL https://ollama.com/install.sh | sh
RUN OLLAMA_HOST=0.0.0.0:11434 ollama serve & \
    sleep 5 && \
    ollama pull gemma3n:e4b && \
    pkill ollama || true

COPY start-services.sh /usr/local/bin/start-services.sh

COPY test/smoke.sh /test/smoke.sh
RUN bash -x /test/smoke.sh

LABEL org.containers.toolbox="true"

EXPOSE 11434
ENTRYPOINT ["/usr/local/bin/start-services.sh"]
