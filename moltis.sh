#!/usr/bin/env sh
# scripted/written by Robert Bopko (github.com/zeroznet) with Boba Bott (Claude Sonnet 4.6)
set -eu

# --- config ---
DOCKER_MODE=sudo
NAME=moltis
IMAGE=ghcr.io/moltis-org/moltis:latest
CONFIG_DIR=/home/moltis/.config/moltis
DATA_DIR=/home/moltis/.moltis
TZ_NAME=Europe/Prague
DOCKER_SOCK=/var/run/docker.sock

# --- helpers ---
log()      { printf '[moltis] %s\n' "$*"; }
warn()     { printf '[moltis] warn: %s\n' "$*" >&2; }
die()      { printf '[moltis] error: %s\n' "$*" >&2; exit 1; }
has_cmd()  { command -v "$1" >/dev/null 2>&1; }
need_cmd() { has_cmd "$1" || die "missing required command: $1"; }

usage() {
  printf 'Usage: %s <command>\n\n' "$0"
  printf 'Commands:\n'
  printf '  install     pull image, create dirs, start container (prompts for password)\n'
  printf '  update      pull latest image and restart container\n'
  printf '  start       start stopped container\n'
  printf '  stop        stop running container\n'
  printf '  restart     restart container\n'
  printf '  logs        follow container logs (last 1 minute)\n'
  printf '  status      show container status\n'
  printf '  version     print moltis binary version\n'
  printf '  auth-reset  reset moltis password interactively\n'
}

docker_cmd() {
  case "$DOCKER_MODE" in
    direct) docker "$@" ;;
    sudo)   sudo docker "$@" ;;
    *)      die "invalid DOCKER_MODE: $DOCKER_MODE" ;;
  esac
}

docker_gid() {
  gid=
  if has_cmd getent; then
    gid=$(getent group docker 2>/dev/null | awk -F: 'NR==1{print $3}') || true
  fi
  if [ -z "$gid" ] && [ -S "$DOCKER_SOCK" ]; then
    gid=$(stat -c '%g' "$DOCKER_SOCK" 2>/dev/null) || true
  fi
  [ -n "$gid" ] || die "could not determine docker gid"
  printf '%s\n' "$gid"
}

prompt_password() {
  old_stty=$(stty -g 2>/dev/null || true)
  trap 'stty "$old_stty" 2>/dev/null || true; printf "\n" >&2; exit 130' INT TERM HUP

  printf 'Moltis password: ' >&2
  stty -echo
  IFS= read -r pw
  stty "$old_stty" 2>/dev/null || true
  trap - INT TERM HUP
  printf '\n' >&2

  [ -n "$pw" ] || die "empty password"
  printf '%s\n' "$pw"
}

run_container() {
  docker_cmd run -d \
    --name "$NAME" \
    --restart unless-stopped \
    --add-host=host.docker.internal:host-gateway \
    --group-add "$DOCKER_GID" \
    -e "TZ=$TZ_NAME" \
    "$@" \
    -p 127.0.0.1:13131:13131 \
    -p 127.0.0.1:13132:13132 \
    -p 127.0.0.1:1455:1455 \
    -v "$CONFIG_DIR:/home/moltis/.config/moltis" \
    -v "$DATA_DIR:/home/moltis/.moltis" \
    -v "$DOCKER_SOCK:/var/run/docker.sock" \
    -v /etc/localtime:/etc/localtime:ro \
    "$IMAGE"
}

need_cmd docker

cmd=${1:-}

case "$cmd" in
  install)
    log "creating data directories"
    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    DOCKER_GID=$(docker_gid)
    MOLTIS_PASSWORD=$(prompt_password)
    log "pulling $IMAGE"
    docker_cmd pull "$IMAGE"
    log "starting container"
    docker_cmd rm -f "$NAME" >/dev/null 2>&1 || true
    run_container -e "MOLTIS_PASSWORD=$MOLTIS_PASSWORD"
    unset MOLTIS_PASSWORD
    log "done"
    ;;
  update)
    log "creating data directories"
    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    DOCKER_GID=$(docker_gid)
    log "pulling $IMAGE"
    docker_cmd pull "$IMAGE"
    log "restarting container"
    docker_cmd rm -f "$NAME" >/dev/null 2>&1 || true
    run_container
    log "done"
    ;;
  start)
    docker_cmd start "$NAME"
    ;;
  stop)
    docker_cmd stop "$NAME"
    ;;
  restart)
    docker_cmd restart "$NAME"
    ;;
  logs)
    docker_cmd logs -f --since=1m "$NAME"
    ;;
  status)
    docker_cmd ps -a --filter "name=^${NAME}$"
    ;;
  version)
    docker_cmd exec -it "$NAME" moltis --version
    ;;
  auth-reset)
    docker_cmd exec -it "$NAME" moltis auth reset-password
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
