#!/usr/bin/env bash
set -euo pipefail
WORKSPACE=${1:?usage: full_install_check.sh WORKSPACE REQUIREMENTS [EXCLUDE_REGEX]}
REQ=${2:?missing requirements file}
EXCLUDE_REGEX=${3:-'^(pywin32|kaleido)=='}
IMAGE=${MANYLINUX_IMAGE:-ghcr.io/loong64/manylinux_2_38_loongarch64:2026.06.04-1}
mkdir -p "$WORKSPACE/logs"

docker run --rm --entrypoint /bin/bash \
  -v "$WORKSPACE:/work" \
  -v "$REQ:/tmp/input-requirements.txt:ro" \
  -e PIP_CACHE_DIR=/tmp/pip-cache \
  "$IMAGE" -c "set -euo pipefail
export PATH=/opt/python/cp311-cp311/bin:\$PATH
PY=/opt/python/cp311-cp311/bin/python
\$PY -m venv /tmp/venv-full-check
source /tmp/venv-full-check/bin/activate
python -m pip install -U pip
python - <<'PY'
import re
from pathlib import Path
rx = re.compile(r'$EXCLUDE_REGEX', re.I)
lines = []
for line in Path('/tmp/input-requirements.txt').read_text().splitlines():
    s = line.strip()
    if not s or rx.search(s):
        continue
    lines.append(s)
Path('/tmp/requirements-filtered.txt').write_text('\n'.join(lines) + '\n')
print('filtered_requirements', len(lines))
PY
python -m pip install --only-binary=:all: --find-links /work/repaired -i https://lpypi.loongnix.cn/loongson/pypi/+simple --extra-index-url https://pypi.org/simple -r /tmp/requirements-filtered.txt 2>&1 | tee /work/logs/full-install-check.log
python - <<'PY'
mods = ['numpy','pandas','scipy','sklearn','statsmodels','matplotlib','lightgbm','pmdarima','tsdownsample']
for mod in mods:
    m = __import__(mod)
    print(mod, getattr(m, '__version__', 'imported'))
PY
"
