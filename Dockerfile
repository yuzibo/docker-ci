FROM debian:sid as builder
MAINTAINER Bo YU "tsu.yubo@gmail.com"

ARG DEBIAN_FRONTEND=noninteractive

RUN --mount=type=cache,sharing=shared,target=/var/cache \
    --mount=type=cache,sharing=shared,target=/var/lib/apt/lists \
    --mount=type=tmpfs,target=/usr/share/man \
    --mount=type=tmpfs,target=/usr/share/doc \
    apt-get update \
    && apt-get install -y eatmydata \
    && eatmydata apt-get install -y debootstrap qemu-user-static \
        binfmt-support debian-ports-archive-keyring gdisk kpartx \
        parted

WORKDIR /builder
COPY create_image.sh ./
COPY build.sh ./
COPY setup_rootfs.sh ./
RUN ls -l

CMD eatmydata /builder/build.sh


