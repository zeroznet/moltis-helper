# moltis-helper

Docker/Podman management wrapper for [Moltis](https://moltis.org/) — a secure personal AI agent server.

## What it does

- installs Moltis as a container with a single command (Docker or rootless Podman)
- handles image pulls and container lifecycle (start / stop / restart / logs)
- prompts for password on first install, passes it securely to the container
- on Podman: exports sandbox image from buildkit cache to Podman store automatically

## Install

### Docker

```sh
curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o ~/bin/moltis && chmod +x ~/bin/moltis
```

### Podman (rootless)

```sh
curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o ~/bin/moltis && chmod +x ~/bin/moltis

curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/podman-shim.sh \
  -o ~/bin/podman-shim && chmod +x ~/bin/podman-shim
```

`podman-shim` is a one-liner wrapper (`exec docker "$@"`) that lets Moltis detect the Podman backend inside the container. Set `PODMAN_SHIM` in the config block if you install it elsewhere.

## Commands

```sh
moltis install        # first-time setup: pull image, prompt for password, start
moltis update         # pull latest image and restart
moltis start          # start stopped container
moltis stop           # stop running container
moltis restart        # restart container
moltis logs           # follow logs (last 1 min)
moltis status         # show container status
moltis version        # print Moltis version
moltis auth-reset     # reset password interactively
moltis sandbox-export # export sandbox image from buildkit to Podman store
```

## Config

Edit the config block at the top of `moltis.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `RUNTIME` | `podman` | Container runtime: `podman` or `docker` |
| `DOCKER_MODE` | `sudo` | For Docker: `sudo` or `direct` |
| `IMAGE` | `ghcr.io/moltis-org/moltis:latest` | Image to pull and run |
| `CONFIG_DIR` | `/home/zero/.config/moltis` | Host path for config volume |
| `DATA_DIR` | `/home/zero/.moltis` | Host path for data volume |
| `TZ_NAME` | `Europe/Prague` | Container timezone |
| `PODMAN_SHIM` | `/home/zero/bin/podman-shim` | Path to podman-shim binary (Podman only) |

## Files

- `moltis.sh` — container management wrapper (Docker + Podman)
- `podman-shim.sh` — Podman backend detection shim (Podman installs only)

## License

Licensed under the BSD-2-Clause license. See LICENSE.
