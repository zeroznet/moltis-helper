#!/usr/bin/env sh
# scripted/written by Robert Bopko (github.com/zeroznet) with Boba Bott (Claude Sonnet 4.6)
set -eu

RUNTIME=podman
DOCKER_MODE=sudo
NAME=moltis
IMAGE=ghcr.io/moltis-org/moltis:latest
CONFIG_DIR=/home/zero/.config/moltis
DATA_DIR=/home/zero/.moltis
TZ_NAME=Europe/Prague

log()      { printf '%s\n' "$*"; }
warn()     { printf 'WARN: %s\n' "$*" >&2; }
die()      { printf 'ERROR: %s\n' "$*" >&2; exit 1; }
has_cmd()  { command -v "$1" >/dev/null 2>&1; }
need_cmd() { has_cmd "$1" || die "Missing required command: $1"; }

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
  printf '\nRuntime: set RUNTIME=docker or RUNTIME=podman at top of script (default: podman)\n'
  printf '  DOCKER_MODE=sudo|direct   skip sudo for docker (default: sudo)\n'
}

validate_runtime() {
  case "$RUNTIME" in
    docker|podman) ;;
    *) die "invalid RUNTIME: $RUNTIME (use docker or podman)" ;;
  esac
  need_cmd "$RUNTIME"
}

runtime_cmd() {
  case "$RT" in
    docker)
      case "$DOCKER_MODE" in
        direct) docker "$@" ;;
        sudo)   sudo docker "$@" ;;
        *)      die "invalid DOCKER_MODE: $DOCKER_MODE" ;;
      esac
      ;;
    podman)
      podman "$@"
      ;;
  esac
}

docker_gid() {
  gid=
  if has_cmd getent; then
    gid=$(getent group docker 2>/dev/null | awk -F: 'NR==1{print $3}') || true
  fi
  if [ -z "$gid" ] && [ -S /var/run/docker.sock ]; then
    gid=$(stat -c '%g' /var/run/docker.sock 2>/dev/null) || true
  fi
  [ -n "$gid" ] || die "could not determine docker gid"
  printf '%s\n' "$gid"
}

container_sock() {
  case "$RT" in
    docker) printf '/var/run/docker.sock' ;;
    podman)
      sock=$(podman info --format '{{.Host.RemoteSocket.Path}}' 2>/dev/null) || true
      [ -n "$sock" ] || sock="/run/user/$(id -u)/podman/podman.sock"
      if [ ! -S "$sock" ]; then
        mkdir -p "$(dirname "$sock")"
        systemctl --user enable podman.socket 2>/dev/null || true
        systemctl --user restart podman.socket
        i=0
        while [ $i -lt 10 ] && [ ! -S "$sock" ]; do
          sleep 1; i=$((i+1))
        done
        [ -S "$sock" ] || die "podman socket not found at $sock"
      fi
      printf '%s' "$sock"
      ;;
  esac
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
  sock=$(container_sock)
  case "$RT" in
    docker)
      runtime_cmd run -d \
        --name "$NAME" \
        --restart unless-stopped \
        --add-host=host.docker.internal:host-gateway \
        --group-add "$DOCKER_GID" \
        --stop-timeout 30 \
        -e "TZ=$TZ_NAME" \
        "$@" \
        -p 127.0.0.1:13131:13131 \
        -p 127.0.0.1:13132:13132 \
        -p 127.0.0.1:1455:1455 \
        -v "$CONFIG_DIR:/home/moltis/.config/moltis" \
        -v "$DATA_DIR:/home/moltis/.moltis" \
        -v "$sock:/var/run/docker.sock" \
        -v /etc/localtime:/etc/localtime:ro \
        "$IMAGE"
      ;;
    podman)
      runtime_cmd run -d \
        --name "$NAME" \
        --restart unless-stopped \
        --userns=keep-id:uid=1000,gid=1001 \
        --add-host=host.docker.internal:host-gateway \
        --stop-timeout 30 \
        -e "TZ=$TZ_NAME" \
        "$@" \
        -p 127.0.0.1:13131:13131 \
        -p 127.0.0.1:13132:13132 \
        -p 127.0.0.1:1455:1455 \
        -v "$CONFIG_DIR:/home/moltis/.config/moltis" \
        -v "$DATA_DIR:/home/moltis/.moltis" \
        -v "$sock:/var/run/docker.sock" \
        -v /etc/localtime:/etc/localtime:ro \
        "$IMAGE"
      ;;
  esac
}

validate_runtime
RT=$RUNTIME
log "runtime: $RT"

cmd=${1:-}

case "$cmd" in
  install)
    log "creating data directories"
    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    DOCKER_GID=
    [ "$RT" = docker ] && DOCKER_GID=$(docker_gid)
    MOLTIS_PASSWORD=$(prompt_password)
    log "pulling $IMAGE"
    runtime_cmd pull "$IMAGE"
    log "starting container"
    runtime_cmd rm -f "$NAME" >/dev/null 2>&1 || true
    run_container -e "MOLTIS_PASSWORD=$MOLTIS_PASSWORD"
    unset MOLTIS_PASSWORD
    log "done"
    ;;
  update)
    log "creating data directories"
    mkdir -p "$CONFIG_DIR" "$DATA_DIR"
    DOCKER_GID=
    [ "$RT" = docker ] && DOCKER_GID=$(docker_gid)
    log "pulling $IMAGE"
    runtime_cmd pull "$IMAGE"
    log "restarting container"
    runtime_cmd rm -f "$NAME" >/dev/null 2>&1 || true
    run_container
    log "done"
    ;;
  start)
    runtime_cmd start "$NAME"
    ;;
  stop)
    runtime_cmd stop "$NAME"
    ;;
  restart)
    runtime_cmd restart "$NAME"
    ;;
  logs)
    runtime_cmd logs -f --since=1m "$NAME"
    ;;
  status)
    runtime_cmd ps -a --filter "name=^${NAME}$"
    ;;
  version)
    runtime_cmd exec -it "$NAME" moltis --version
    ;;
  auth-reset)
    runtime_cmd exec -it "$NAME" moltis auth reset-password
    ;;
  help|-h|--help)
    usage
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
