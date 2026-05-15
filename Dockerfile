FROM ubuntu:25.10

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    bc \
    bison \
    ca-certificates \
    cargo \
    clang \
    curl \
    elfutils \
    flex \
    gcc \
    g++ \
    git \
    libcap-ng-dev \
    libclang-dev \
    libelf-dev \
    llvm \
    make \
    patch \
    perl \
    python3-pyelftools \
    rustc \
    tar \
    wget \
    xz-utils \
    zstd \
    && rm -rf /var/lib/apt/lists/*
