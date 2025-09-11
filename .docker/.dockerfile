FROM ubuntu:22.04

# Avoid interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-dev \
    make \
    iverilog \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Install cocotb using pip
RUN pip3 install cocotb

# Set the default working directory inside the container
WORKDIR /github/workspace