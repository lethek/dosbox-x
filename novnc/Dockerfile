# syntax=docker/dockerfile:1

# Adds a VNC server and noVNC (browser UI) on top of the dosbox-x image.

ARG BASE_IMAGE=ghcr.io/lethek/dosbox-x:latest
FROM ${BASE_IMAGE}

ARG NOVNC_VERSION=1.7.0
ARG NOVNC_SHA256=b1003a11b6e6e8d8f7f5e5586daae7f8ca651d8aee0aa155ff9ac841c48f52c6
ENV DEBIAN_FRONTEND=noninteractive
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
      tigervnc-standalone-server tigervnc-tools websockify iproute2 procps \
      ca-certificates curl \
    && rm -rf /var/lib/apt/lists/* \
    && mkdir -p /usr/share/novnc \
    && curl -fsSL -o /tmp/novnc.tgz "https://github.com/novnc/noVNC/archive/refs/tags/v${NOVNC_VERSION}.tar.gz" \
    && echo "${NOVNC_SHA256}  /tmp/novnc.tgz" | sha256sum -c - \
    && tar -xzf /tmp/novnc.tgz -C /usr/share/novnc --strip-components=1 \
    && rm /tmp/novnc.tgz \
    && ln -s vnc.html /usr/share/novnc/index.html
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh
USER 1000:1000
ENV DISPLAY=:1 \
    VNCGEOMETRY=1024x768 \
    VNCDEPTH=24 \
    AUTOSLEEP=1
EXPOSE 5901 8080
ENTRYPOINT ["/usr/local/bin/start.sh"]
