FROM vllm/vllm-openai:nightly

ARG DEBIAN_FRONTEND=noninteractive

# Install dev tools not in the base image
RUN apt-get update && apt-get install -y \
    zsh \
    ripgrep \
    bat \
    tmux \
    less \
    && rm -rf /var/lib/apt/lists/*

# Copy dotfiles and install
COPY . /root/.dotfiles
WORKDIR /root/.dotfiles
RUN bash install.sh

# Set default shell
ENV SHELL=/usr/bin/zsh
WORKDIR /root
ENTRYPOINT ["/usr/bin/zsh"]
