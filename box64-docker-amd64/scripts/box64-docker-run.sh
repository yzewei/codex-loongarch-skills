#!/usr/bin/env bash
set -euo pipefail

default_box64=/home/yzw/python-trans/box64-up/build-static-trace-v2/box64
box64_bin=${BOX64_BIN:-$default_box64}
container_box64=/opt/box64

usage() {
    cat <<'EOF'
Usage:
  box64-docker-run.sh [DOCKER_OPTIONS...] -- IMAGE GUEST [ARG...]

Examples:
  box64-docker-run.sh -- debian:bookworm-slim /bin/bash
  box64-docker-run.sh -- ngrok/ngrok:latest /bin/sh -lc 'ngrok version'
  box64-docker-run.sh -e TS3SERVER_LICENSE=accept -- \
    teamspeak:latest /bin/sh /opt/ts3server/entrypoint.sh ts3server

Environment:
  BOX64_BIN                 Host path to static Box64
  BOX64_LOG                 Box64 log level, default 1
  BOX64_TRACE               Optional Box64 instruction trace setting
  BOX64_TRACE_FILE          Optional trace output path inside container
  BOX64_EMULATED_LIBS       Optional colon-separated guest libraries to emulate
  BOX64_LD_LIBRARY_PATH     Optional guest x86_64 library search path
  BOX64_DOCKER_USE_SUDO     Set to 1 to execute sudo docker
EOF
}

if [[ ${1:-} == -h || ${1:-} == --help ]]; then
    usage
    exit 0
fi

docker_options=()
while (($#)); do
    if [[ $1 == -- ]]; then
        shift
        break
    fi
    docker_options+=("$1")
    shift
done

if (($# < 2)); then
    usage >&2
    exit 2
fi

image=$1
shift

if [[ ! -x $box64_bin ]]; then
    printf 'Box64 is not executable: %s\n' "$box64_bin" >&2
    exit 1
fi

if ! file "$box64_bin" | grep -q 'statically linked'; then
    printf 'Box64 must be statically linked: %s\n' "$box64_bin" >&2
    exit 1
fi

if [[ ${BOX64_DOCKER_USE_SUDO:-0} == 1 ]]; then
    docker_cmd=(sudo docker)
else
    docker_cmd=(docker)
fi

box64_env=(-e "BOX64_LOG=${BOX64_LOG:-1}")
if [[ -n ${BOX64_TRACE:-} ]]; then
    box64_env+=(-e "BOX64_TRACE=$BOX64_TRACE")
fi
if [[ -n ${BOX64_TRACE_FILE:-} ]]; then
    box64_env+=(-e "BOX64_TRACE_FILE=$BOX64_TRACE_FILE")
fi
if [[ -n ${BOX64_EMULATED_LIBS:-} ]]; then
    box64_env+=(-e "BOX64_EMULATED_LIBS=$BOX64_EMULATED_LIBS")
fi
if [[ -n ${BOX64_LD_LIBRARY_PATH:-} ]]; then
    box64_env+=(-e "BOX64_LD_LIBRARY_PATH=$BOX64_LD_LIBRARY_PATH")
fi

run_options=(--rm)
if [[ -t 0 && -t 1 ]]; then
    run_options+=(-it)
fi

exec "${docker_cmd[@]}" run "${run_options[@]}" \
    --platform linux/amd64 \
    --entrypoint "$container_box64" \
    -v "$box64_bin:$container_box64:ro" \
    "${box64_env[@]}" \
    "${docker_options[@]}" \
    "$image" "$@"
