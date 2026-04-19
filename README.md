# moltis-helper

Docker management wrapper for [Moltis](https://moltis.org/) — a secure personal AI agent server.

## What it does

- installs Moltis as a Docker container with a single command
- handles image pulls and container lifecycle (start / stop / restart / logs)
- prompts for password on first install, passes it securely to the container
- resolves Docker GID automatically for socket access

## One-line install

```sh
curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o ~/bin/moltis && chmod +x ~/bin/moltis
```

Or to `/usr/local/bin` (may require sudo):

```sh
sudo curl -fsSL https://raw.githubusercontent.com/zeroznet/moltis-helper/main/moltis.sh \
  -o /usr/local/bin/moltis && sudo chmod +x /usr/local/bin/moltis
```

## Usage

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

## Configuration

Edit the config block at the top of `moltis.sh`:

| Variable      | Default                            | Description                          |
|---------------|------------------------------------|--------------------------------------|
| `DOCKER_MODE` | `sudo`                             | `sudo` or `direct`                   |
| `IMAGE`       | `ghcr.io/moltis-org/moltis:latest` | image to pull and run                |
| `TZ_NAME`     | `Europe/Prague`                    | container timezone                   |
| `CONFIG_DIR`  | `/home/moltis/.config/moltis`      | host path for config volume          |
| `DATA_DIR`    | `/home/moltis/.moltis`             | host path for data volume            |

## Files

- `moltis.sh` — the script

## License

[BSD-2-Clause](LICENSE)
