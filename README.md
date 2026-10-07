# dosbox-x

DOSBox-X built from source, served through a VNC server and noVNC in the browser. Upstream publishes no Linux binaries or container image, so this builds one.

## Sources

- DOSBox-X: <https://github.com/joncampbell123/dosbox-x> (GPL-2.0), built from the release tag named by `DOSBOX_X_VERSION` in the `Dockerfile`, with its sha256 checked.
- noVNC: <https://github.com/novnc/noVNC> (MPL-2.0), the release named by `NOVNC_VERSION`, with its sha256 checked.
- Runtime packages (TigerVNC, websockify and libraries) come from Ubuntu 24.04.

This repository only contains the build files, not DOSBox-X source. It is not affiliated with the DOSBox-X project.

## Images

| Image | Contents |
|---|---|
| `ghcr.io/lethek/dosbox-x` | DOSBox-X only. Runs as uid 1000, needs an X display (`DISPLAY`). Entrypoint is `dosbox-x`. |
| `ghcr.io/lethek/dosbox-x-novnc` | The image above plus TigerVNC, websockify and noVNC, so it runs standalone and is used from a browser. |

Both are tagged with the DOSBox-X version (for example `2026.10.01`) and `latest`.

## dosbox-x-novnc

- Browser UI on port 8080, raw VNC on port 5901.
- Mount a volume at `/config` (config, logs, `drive_d`).
- `VNCPASSWORD` (or `VNCPASS`): VNC password, first 8 characters are used. A random one is logged at startup if unset.
- `VNCAUTH=none` disables the password for both VNC and noVNC. Only use it on a trusted network.
- `AUTOSLEEP=1` (default) pauses DOSBox-X while no VNC client is connected.
- `VNCGEOMETRY` (default `1024x768`) and `VNCDEPTH` (default `24`).

To bump DOSBox-X, change `DOSBOX_X_VERSION` and `DOSBOX_X_SHA256` in `base/Dockerfile`. To bump noVNC, change `NOVNC_VERSION` and `NOVNC_SHA256` in `novnc/Dockerfile`.
