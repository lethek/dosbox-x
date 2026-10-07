# syntax=docker/dockerfile:1

# Builds DOSBox-X from source (upstream publishes no Linux binaries) and serves it
# through a VNC server and noVNC in the browser.

ARG UBUNTU_TAG=24.04

FROM ubuntu:${UBUNTU_TAG} AS build
ARG DOSBOX_X_VERSION=2026.10.01
ARG DOSBOX_X_SHA256=df023a6c0e4a139dcbd60befff5947e0db2cc68e4e79db463670f581a4044ed4
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      automake autoconf libtool gcc g++ make nasm pkg-config ca-certificates curl \
      libncurses-dev libsdl2-dev libsdl2-net-dev libpcap-dev libslirp-dev \
      libfluidsynth-dev libfreetype-dev libpng-dev libxkbfile-dev libxrandr-dev \
      libx11-dev libxi-dev libasound2-dev \
    && rm -rf /var/lib/apt/lists/*
WORKDIR /src
RUN curl -fsSL -o src.tgz "https://github.com/joncampbell123/dosbox-x/archive/refs/tags/dosbox-x-v${DOSBOX_X_VERSION}.tar.gz" \
    && echo "${DOSBOX_X_SHA256}  src.tgz" | sha256sum -c - \
    && tar -xzf src.tgz --strip-components=1 \
    && rm src.tgz
RUN ./build-sdl2 \
    && make install DESTDIR=/stage

FROM ubuntu:${UBUNTU_TAG}
ARG NOVNC_VERSION=1.7.0
ARG NOVNC_SHA256=b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      tigervnc-standalone-server tigervnc-tools websockify iproute2 procps \
      ca-certificates curl \
      libsdl2-2.0-0 libsdl2-net-2.0-0 libpcap0.8t64 libslirp0 libfluidsynth3 \
      libfreetype6 libpng16-16t64 libxkbfile1 libxrandr2 libncurses6 fluid-soundfont-gm \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/share/novnc \
    && curl -fsSL -o /tmp/novnc.tgz "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
    && echo "${NOVNC_SHA256}  /tmp/novnc.tgz" | sha256sum -c - \
    && tar -xzf /tmp/novnc.tgz -C /usr/share/novnc --strip-components=1 \
    && rm /tmp/novnc.tgz \
    && ln -s vnc.html /usr/share/novnc/index.html
COPY --from=build /stage/usr/ /usr/
COPY start.sh /usr/local/bin/start.sh

# 1000 is the default non-root user in the Ubuntu base image.
RUN userdel -r ubuntu 2>/dev/null; useradd -u 1000 -m -s /bin/bash dosbox \
    && mkdir -p /config && chown dosbox:dosbox /config \
    && chmod +x /usr/local/bin/start.sh
USER 1000:1000
ENV HOME=/home/dosbox \
    DISPLAY=:1 \
    SDL_AUDIODRIVER=dummy \
    VNCGEOMETRY=1024x768 \
    VNCDEPTH=24 \
    AUTOSLEEP=1
EXPOSE 5901 8080
ENTRYPOINT ["/usr/local/bin/start.sh"]
