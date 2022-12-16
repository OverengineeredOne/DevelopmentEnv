#syntax=docker/dockerfile:1
FROM ubuntu:latest as base

RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata
RUN apt-get install -y \
	apt-utils \
	build-essential \
	curl \
	git-all \
	openssh-server

# Install required packages to set up K3s managed by flux & terraform
FROM homebrew/brew:latest as k3sinstaller

RUN brew install age
RUN brew install ansible
RUN brew install direnv
RUN brew install fluxcd/tap/flux
RUN brew install gitleaks
RUN brew install golang
RUN brew install go-task/tap/go-task
RUN brew install helm
RUN brew install ipcalc
RUN brew install jq
RUN brew install kubectl
RUN brew install kustomize
RUN brew install pre-commit
RUN brew install prettier
RUN brew install sops
RUN brew install stern
RUN brew install terraform
RUN brew install yamllint
RUN brew install yq

# Update all brew installs to help with cache and image size.
FROM k3sinstaller as k3sinstaller_update

RUN brew update

FROM rust:latest as cargodevtools

RUN cargo install trunk
RUN cargo install mdbook
RUN cargo install oecli

# Attempt at a minimized brew installation. We don't want to assume the user will use brew as a 
# package manager or use any of the dependency build tools. There are shared linkers that are 
# expected in the default hombrew path.
# FROM base as minik3sinstaller

# RUN apt-get update && \
	# apt-get -y install sudo

# ARG BREW_DIR=/home/linuxbrew/.linuxbrew
# ARG CELLAR_DIR=${BREW_DIR}/Cellar
# ARG LOCAL_BREW=/usr/local/brew


# ! WARNING ! Here be dragons ! Fragile tying this to a specific version is not a good idea
# To minimze final image size, only move over what is needed.
# 	moving over just these hard coded versions might be a bad idea.
#   brew creates an symlink to the latest version, can we use this path?
# 		doesn't seem to be supported https://github.com/moby/moby/issues/1676

# Since homebrew uses a different linker than the system, we copy over the dependencies such as 
# ld.so path is expected to be within brew. Might be able to update path to look in another 
# directory.
# COPY --from=k3sinstaller_update ${BREW_DIR}/lib ${BREW_DIR}/lib
# COPY --from=k3sinstaller_update ${BREW_DIR}/include ${BREW_DIR}/include

# Python 3.10 is required for several dependencies
# COPY --from=k3sinstaller_update ${BREW_DIR}/opt/python@3.10/ ${BREW_DIR}/opt/python@3.10/

# COPY --from=k3sinstaller_update ${CELLAR_DIR}/age/1.0.0/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/direnv/2.32.0/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/flux/0.31.1/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/gitleaks/8.8.7/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/go-task/3.13.0/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/helm/3.9.0/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/ipcalc/0.51/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/kustomize/4.5.5/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/sops/3.7.3/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/terraform/1.2.3/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/yq/4.25.2/bin/ ${LOCAL_BREW}/.

# ! Very hacky ! brew install points to the relative path to find python3.10, which brew points to
# a shared instalation. We also need to update the library path so it can find dependencies, 
# currently does not work
# RUN sed -i "1s/.*/\#\!\/usr\/local\/brew\/python3.10/" ${LOCAL_BREW}/pre-commit
# ENV LD_LIBRARY_PATH ${LD_LIBRARY_PATH}:/home/linuxbrew/.linuxbrew/opt/python@3.10/lib
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/pre-commit/2.19.0/libexec/bin/ \
	# ${LOCAL_BREW}/.

# Ansible does not work python dependencies
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/ansible/5.9.0/libexec/bin/ ${LOCAL_BREW}/.

# yamllint does not work python dependencies
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/yamllint/1.26.3_1/libexec/bin/ \
	# ${LOCAL_BREW}/.

# Error loading shared lib: liboning.so.5
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/jq/1.6/bin/ ${LOCAL_BREW}/.
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/kubernetes-cli/1.24.2/bin/ ${LOCAL_BREW}/.

# Depends on npm
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/prettier/2.7.1/libexec/bin/ ${LOCAL_BREW}/.

# Untested
# COPY --from=k3sinstaller_update ${CELLAR_DIR}/stern/1.21.0/bin/ ${LOCAL_BREW}/.

# Remove brews symlink and place our own.
# RUN rm /usr/local/brew/python3.10
# RUN ln -s /home/linuxbrew/.linuxbrew/opt/python@3.10/bin/python3.10 /usr/local/brew/python3.10

# !!! WARNING !!! 
# COPYS EVERYTHING FROM BREW DIR. REMOVE ONCE ONLY BINARIES ARE MOVED. 
# makes it easier to ssh into container debug
# COPY --from=k3sinstaller_update /home/linuxbrew/.linuxbrew/ /usr/local/brewcopy/.

# Ensure path is accessaible within the ssh client with etc profile
# RUN echo "PATH=$PATH:/usr/local/brew" | sudo tee -a /etc/profile.d/path.sh

FROM base as devtools

# Set up sudo
RUN apt-get update && \
	apt-get -y install sudo

# Copy from brew and cargo tools. Currently minik3sinstaller is not working
COPY --from=k3sinstaller_update /home/linuxbrew/.linuxbrew/ /home/linuxbrew/.linuxbrew/
COPY --from=cargodevtools usr/local/cargo/bin/trunk /opt/.cargo/bin/trunk
COPY --from=cargodevtools usr/local/cargo/bin/mdbook /opt/.cargo/bin/mdbook
COPY --from=cargodevtools usr/local/cargo/bin/oecli /opt/.cargo/bin/oecli

# Install python
RUN apt-get -y install python3 python3-pip

# Github Cli
RUN curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
RUN sudo apt-get update
RUN sudo apt-get install gh -y

# Rust
ENV CARGO_HOME /opt/.cargo
ENV RUSTUP_HOME /opt/.rust
RUN mkdir ${RUSTUP_HOME}
RUN echo "PATH=$PATH:${CARGO_HOME}/bin\nCARGO_HOME=$CARGO_HOME\nRUSTUP_HOME=$RUSTUP_HOME" | \
	sudo tee -a /etc/environment
RUN curl https://sh.rustup.rs -sSf | sudo bash -s -- -y

FROM devtools
EXPOSE 22

# Setup User Account (this should be moved into it's own step?)
ENV USER oe
RUN useradd -m -d /home/${USER} ${USER} && \
	chown -R ${USER} /home/${USER} && \
	adduser ${USER} sudo && \
	echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo "oe:password" | chpasswd
USER ${USER}
WORKDIR /home/${USER}
RUN sudo apt-get update

RUN sudo chown -R ${USER}:${USER} ${CARGO_HOME}
RUN sudo chown -R ${USER}:${USER} ${RUSTUP_HOME}

# Set up default shell
RUN sudo usermod -s /bin/bash ${USER}

# Enable SSH and leave bash open.
ENTRYPOINT sudo service ssh restart && bash

# TODOs: 
# - user account and credentials should be passed in as an arg
# - Set up CI w/ repo & dependencies

