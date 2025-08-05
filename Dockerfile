FROM registry.fedoraproject.org/fedora-toolbox:42

RUN dnf -y upgrade && dnf -y install zsh make git podman fuse-overlayfs slirp4netns golang npm pnpm ripgrep fzf curl jq libxcrypt-compat.x86_64 && dnf clean all

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

RUN dnf -y install podman-remote && dnf clean all
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

RUN dnf -y install gcc-c++ make cmake pkgconfig && dnf clean all

RUN dnf -y install python3.12 python3.12-devel python3-pip \
 && alternatives --set python3 /usr/bin/python3.12 \
 && dnf clean all \
 && python3 -m venv /opt/comfy-venv \
 && . /opt/comfy-venv/bin/activate \
 && pip install --upgrade pip \
 && pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu128 \
 && git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git /opt/ComfyUI \
 && pip install -r /opt/ComfyUI/requirements.txt

RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager.git /opt/ComfyUI/custom_nodes/ComfyUI-Manager
RUN git clone --depth=1 https://github.com/city96/ComfyUI-GGUF.git /opt/ComfyUI/custom_nodes/ComfyUI-GGUF

RUN mkdir -p /opt/ComfyUI/models/diffusion_models \
 && curl -L https://huggingface.co/city96/Qwen-Image-gguf/resolve/main/qwen-image-Q4_0.gguf \
        -o /opt/ComfyUI/models/diffusion_models/qwen-image-Q4_0.gguf \
RUN mkdir -p /opt/ComfyUI/models/text_encoders \
 && curl -L https://huggingface.co/Comfy-Org/Qwen-Image_ComfyUI/resolve/main/split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
        -o /opt/ComfyUI/models/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors \
RUN mkdir -p /opt/ComfyUI/models/vae \
 && curl -L https://huggingface.co/Qwen/Qwen-Image/resolve/main/vae/diffusion_pytorch_model.safetensors \
        -o /opt/ComfyUI/models/vae/qwen_image_vae.safetensors

RUN cat <<'EOF' > /etc/profile.d/91-start-ai-stack.sh
#!/usr/bin/env bash
set -euo pipefail

if [ -f /run/.containerenv ] && [[ $- == *i* ]]; then
  # OLLAMA -------------------------------------------------------------
  if ! pgrep -f "ollama serve" >/dev/null 2>&1; then
    export OLLAMA_HOST=0.0.0.0:11434
    nohup ollama serve \
      </dev/null >/var/log/ollama.log 2>&1 &
  fi

  # ComfyUI ------------------------------------------------------------
  if ! pgrep -f "python.*ComfyUI.*main.py" >/dev/null 2>&1; then
    source /opt/comfy-venv/bin/activate
    (
      cd /opt/ComfyUI
      nohup python main.py --listen 0.0.0.0 --port 8188 \
        </dev/null >/var/log/comfyui.log 2>&1 &
    )
  fi
fi
EOF
RUN chmod +x /etc/profile.d/91-start-ai-stack.sh

COPY test/build/smoke.sh /test/build/smoke.sh
RUN bash -x /test/build/smoke.sh

LABEL org.containers.toolbox="true"

EXPOSE 8188
EXPOSE 11434
