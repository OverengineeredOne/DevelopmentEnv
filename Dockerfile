#syntax=docker/dockerfile:1
FROM ubuntu:latest
EXPOSE 22

RUN apt-get update && \
	apt-get -y install sudo

# Setup User Account
ENV user oe
RUN useradd -m -d /home/${user} ${user} && \
	chown -R ${user} /home/${user} && \
	adduser ${user} sudo && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo "oe:password" | chpasswd

USER ${user}

WORKDIR /home/${user}

RUN sudo apt-get update

# Basic dev tools
RUN DEBIAN_FRONTEND=noninteractive sudo apt-get install -y --no-install-recommends tzdata
RUN sudo apt-get install -y \
	build-essential \
    curl
RUN sudo apt-get update
RUN sudo apt-get install -y neovim

# Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
RUN echo 'source $HOME/.cargo/env' >> $HOME/.bashrc

# Web
RUN ~/.cargo/bin/cargo install trunk
RUN sudo apt-get install -y \
    nodejs \
    npm

# Docs
RUN ~/.cargo/bin/cargo install mdbook

# Tools
RUN ~/.cargo/bin/cargo install oecli

# Github Cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN sudo apt-get update
RUN sudo apt-get install gh -y

# Enable SSH

RUN sudo apt-get install -y openssh-server

ENTRYPOINT service ssh restart && bash
