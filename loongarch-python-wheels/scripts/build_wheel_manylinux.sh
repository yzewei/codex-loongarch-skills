#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${1:?usage: build_wheel_manylinux.sh WORKSPACE PACKAGE_OR_SRC [DNF_PACKAGES] [EXTRA_ENV]}
PKG=${2:?missing package spec or /work source path}
DNF_PACKAGES=${3:-}
EXTRA_ENV=${4:-}
IMAGE=${MANYLINUX_IMAGE:-ghcr.io/loong64/manylinux_2_38_loongarch64:2026.06.04-1}
mkdir -p "$WORKSPACE"/{dist,logs,build,pip-cache}
SAFE_NAME=$(printf '%s' "$PKG" | sed 's#[/= :]#_#g' | tr -cd 'A-Za-z0-9_.-')

docker run --rm --entrypoint /bin/bash \
  -v "$WORKSPACE:/work" \
  -e PIP_CACHE_DIR=/tmp/pip-cache \
  -e TMPDIR=/work/build \
  $EXTRA_ENV \
  "$IMAGE" -c "set -euo pipefail
export PATH=/opt/python/cp311-cp311/bin:\$PATH
PY=/opt/python/cp311-cp311/bin/python
if [ -n '$DNF_PACKAGES' ]; then dnf --disablerepo=crb install -y $DNF_PACKAGES; fi
\$PY -m pip install -U pip setuptools wheel packaging
\$PY -m pip wheel -v --no-deps -i https://lpypi.loongnix.cn/loongson/pypi/+simple --extra-index-url https://pypi.org/simple --wheel-dir /work/dist '$PKG' 2>&1 | tee /work/logs/${SAFE_NAME}-build.log
ls -lh /work/dist
"
