#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${1:-/home/yzw/keda-wheel-build}
mkdir -p "$WORKSPACE"/{requirements,src,dist,repaired,logs,build,pip-cache}
printf 'workspace=%s\n' "$WORKSPACE"
