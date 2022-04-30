#syntax=docker/dockerfile:1
FROM ubuntu:latest
EXPOSE 22

RUN apt-get update

# Basic dev tools
RUN apt-get install -y \
    build-essential \
    curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN apt-get update
RUN apt-get install -y neovim

# Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc

# Web
RUN ~/.cargo/bin/cargo install trunk
RUN apt-get install -y \
    nodejs \
    npm

# Docs
RUN ~/.cargo/bin/cargo install mdbook

# Tools
RUN ~/.cargo/bin/cargo install oecli

# Github Cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN apt-get update
RUN apt-get install gh -y

# Setup User Account
RUN useradd -ms /bin/bash oe 
RUN echo "oe:password" | chpasswd

# Enable SSH

RUN apt-get install -y openssh-server

ENTRYPOINT service ssh restart && bash
