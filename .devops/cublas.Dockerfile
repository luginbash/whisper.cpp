ARG UBUNTU_VERSION=22.04

# This needs to generally match the container host's environment.
ARG CUDA_VERSION=12.2.2

# Target the CUDA build image
ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}

FROM ${BASE_CUDA_DEV_CONTAINER} as build

# Unless otherwise specified, we make a fat build.
ARG CUDA_DOCKER_ARCH=all

RUN apt-get update && \
    apt-get install -y build-essential git cmake curl

WORKDIR /build

RUN curl -fsSL https://github.com/ggerganov/whisper.cpp/archive/refs/heads/master.tar.gz --output - | tar -zx --strip-components=1 -C /build
# Set nvcc architecture
ENV CUDA_DOCKER_ARCH=${CUDA_DOCKER_ARCH}
# Enable cuBLAS
ENV WHISPER_CUBLAS=1
ENV WHISPER_BUILD_EXAMPLES=1
RUN cmake -B build -DWHISPER_CUBLAS=ON && cmake --build build -j --config Release

ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-cudnn8-runtime-ubuntu${UBUNTU_VERSION}
FROM ${BASE_CUDA_DEV_CONTAINER} 

COPY --from=build /build/build/bin/ /usr/local/bin
COPY --from=build /build/build/*.so /lib/x86_64-linux-gnu/


