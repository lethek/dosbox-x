# dosbox-x-container

DOSBox-X built from source, served through a VNC server and noVNC in the browser. Upstream publishes no Linux binaries or container image, so this builds one.

- Image: `ghcr.io/lethek/dosbox-x:<dosbox-x version>`
- Browser UI on port 8080, raw VNC on port 5901
- Runs as uid 1000. Mount a volume at `/config` (config, logs, `drive_d`).
- `VNCPASSWORD`: VNC password (first 8 characters are used). A random one is logged at startup if unset.
- `AUTOSLEEP=1` (default) pauses DOSBox-X while no VNC client is connected.
- `VNCGEOMETRY` (default `1024x768`) and `VNCDEPTH` (default `24`).

To bump DOSBox-X, change `DOSBOX_X_VERSION` and `DOSBOX_X_SHA256` in the `Dockerfile`.
