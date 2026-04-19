# moltis-helper

Docker management wrapper for [Moltis](https://moltis.org/) — a secure personal AI agent server.

## What it does

- installs Moltis as a Docker container with a single command
- handles image pulls and container lifecycle (start / stop / restart / logs)
- prompts for password on first install, passes it securely to the container
- resolves Docker GID automatically for socket access

## One-line install

To `~/bin`:

```sh
curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o ~/bin/moltis && chmod +x ~/bin/moltis
```

To `/usr/local/bin`:

```sh
sudo curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o /usr/local/bin/moltis && sudo chmod +x /usr/local/bin/moltis
```

## Commands

```sh
moltis install      # first-time setup: pull image, prompt for password, start
moltis update       # pull latest image and restart
moltis start        # start stopped container
moltis stop         # stop running container
moltis restart      # restart container
moltis logs         # follow logs (last 1 min)
moltis status       # show container status
moltis version      # print Moltis version
moltis auth-reset   # reset password interactively
```

## Config

Edit the config block at the top of `moltis.sh`:

- `DOCKER_MODE` - `sudo` or `direct` (default: `sudo`)
- `IMAGE` - image to pull and run (default: `ghcr.io/moltis-org/moltis:latest`)
- `TZ_NAME` - container timezone (default: `Europe/Prague`)
- `CONFIG_DIR` - host path for config volume (default: `/home/moltis/.config/moltis`)
- `DATA_DIR` - host path for data volume (default: `/home/moltis/.moltis`)

## Files

- `moltis.sh` - Docker management wrapper for Moltis

## License

Licensed under the BSD-2-Clause license. See LICENSE.
