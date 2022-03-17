#syntax=docker/dockerfile:1
FROM ubuntu:latest
RUN apt-get update

# Basic dev tools
RUN apt-get install -y \
    build-essential \
    curl
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends tzdata

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


