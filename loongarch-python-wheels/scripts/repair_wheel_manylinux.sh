#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${1:?usage: repair_wheel_manylinux.sh WORKSPACE WHEEL_GLOB [DNF_PACKAGES]}
WHEEL_GLOB=${2:?missing wheel glob, use /work/dist/pkg-*.whl}
DNF_PACKAGES=${3:-}
IMAGE=${MANYLINUX_IMAGE:-ghcr.io/loong64/manylinux_2_38_loongarch64:2026.06.04-1}
mkdir -p "$WORKSPACE"/{repaired,logs}
SAFE_NAME=$(basename "$WHEEL_GLOB" | sed 's#[*?/= :]#_#g')

docker run --rm --entrypoint /bin/bash \
  -v "$WORKSPACE:/work" \
  -e LD_LIBRARY_PATH=/usr/lib64:/lib64 \
  "$IMAGE" -c "set -euo pipefail
export PATH=/opt/python/cp311-cp311/bin:\$PATH
if [ -n '$DNF_PACKAGES' ]; then dnf --disablerepo=crb install -y $DNF_PACKAGES; ldconfig; fi
for whl in $WHEEL_GLOB; do
  auditwheel show \"\$whl\" 2>&1 | tee -a /work/logs/${SAFE_NAME}-auditwheel-show.log
  auditwheel repair --plat manylinux_2_38_loongarch64 -w /work/repaired \"\$whl\" 2>&1 | tee -a /work/logs/${SAFE_NAME}-auditwheel-repair.log
done
ls -lh /work/repaired
"
