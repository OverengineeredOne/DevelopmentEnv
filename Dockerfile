#syntax=docker/dockerfile:1
FROM ubuntu:latest
EXPOSE 22

RUN apt-get update && \
	apt-get -y install sudo

# Note for the Rust instalation, Since we may want to mount the home directory to a volume, rust
# will not install under the default. We need to set the environment variables to update the 
# toolchain and cargo path for the root user. This will allow us to install it under opt.

ENV CARGO_HOME /opt/.cargo
ENV RUSTUP_HOME /opt/.rust
ENV PATH ${PATH}:/opt/.cargo/bin
RUN echo "PATH=\"/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/games:/usr/local/games:/snap/bin::/opt/.cargo/bin\"\nCARGO_HOME=\"/opt/.cargo\"\nRUSTUP_HOME=\"/opt/.rust\"" \
	>> /etc/environment

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
	apt-utils \
	build-essential \
    curl \
	openssh-server \
	nodejs \
	npm
RUN sudo apt-get update
RUN sudo apt-get install -y neovim

# Github Cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN sudo apt-get update
RUN sudo apt-get install gh -y

# Rust
RUN curl https://sh.rustup.rs -sSf | sudo bash -s -- -y
RUN echo 'source $CARGO_HOME/env' >> $HOME/.bashrc
RUN sudo chown -R ${user}:${user} /opt/.cargo/
RUN sudo chown -R ${user}:${user} /opt/.rust/

# Web
RUN ${CARGO_HOME}/bin/cargo install trunk

# Docs
RUN ${CARGO_HOME}/bin/cargo install mdbook

# Other Tools
RUN ${CARGO_HOME}/bin/cargo install oecli

# Enable SSH
ENTRYPOINT sudo service ssh restart && bash
