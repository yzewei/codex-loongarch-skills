---
name: loongarch-python-wheels
description: Build, audit, and validate Python 3.11 dependency stacks for LoongArch64 on glibc 2.38+ using manylinux_2_38_loongarch64 Docker, lpypi.loongnix.cn, PyPI fallback, auditwheel, and local wheelhouses. Use when compiling scientific/ML/Dash/Plotly packages such as numpy, scipy, pandas, scikit-learn, matplotlib, lightgbm, pmdarima, tsdownsample, torch, torchvision, pycaret, or diagnosing pywin32/kaleido compatibility on LoongArch.
---

# LoongArch Python Wheels

Use this skill to reproduce a Python 3.11 LoongArch64 wheel build and validation workflow similar to the Keda intelligent kiln project.

## Default Build Policy

- Do not use Anaconda unless the user explicitly requests it.
- Prefer the manylinux image `ghcr.io/loong64/manylinux_2_38_loongarch64:2026.06.04-1` when the requested output must run on glibc 2.38+.
- Mount all source, logs, wheel output, and repair output from the host into the container. Do not leave final artifacts only inside a container.
- Use `lpypi` as primary index and PyPI as fallback:

```bash
-i https://lpypi.loongnix.cn/loongson/pypi/+simple \
--extra-index-url https://pypi.org/simple
```

- Upgrade pip inside fresh venvs before installing LoongArch manylinux wheels. Older pip versions may not recognize `manylinux_2_38_loongarch64` tags.
- Treat `pywin32` as Windows-only unless the target is Windows.
- Treat `kaleido==0.2.1` as a Chromium/Kaleido executable porting problem, not a normal Python extension build.

## Workspace Layout

Use a dedicated workspace, normally:

```text
/work
├── requirements/
├── src/
├── dist/
├── repaired/
├── logs/
├── build/
└── pip-cache/
```

On the host, this is commonly `/home/yzw/keda-wheel-build` and mounted as `/work`.

Run:

```bash
scripts/prepare_workspace.sh /home/yzw/keda-wheel-build
```

## Audit Workflow

1. Confirm Python target and ABI:

```bash
/opt/python/cp311-cp311/bin/python - <<'PY'
import sys, sysconfig, packaging.tags
print(sys.version)
print(sysconfig.get_config_var('SOABI'))
print(next(iter(packaging.tags.sys_tags())))
PY
```

2. For a requirements file, first try binary-only resolution with the wheelhouse:

```bash
scripts/full_install_check.sh /path/to/workspace /path/to/requirements.txt
```

3. If binary-only fails, classify each failure as:

- platform-inapplicable package, such as `pywin32` on Linux;
- source-build package, such as `scipy`, `pandas`, `matplotlib`, `pmdarima`, `tsdownsample`;
- browser/runtime package, such as `kaleido`;
- version conflict or resolver issue.

## Source Build Workflow

Build one package at a time and keep logs.

```bash
scripts/build_wheel_manylinux.sh /home/yzw/keda-wheel-build 'numpy==1.26.4' 'openblas-devel lapack-devel gcc-gfortran'
scripts/repair_wheel_manylinux.sh /home/yzw/keda-wheel-build '/work/dist/numpy-1.26.4-*.whl' 'openblas openblas-devel lapack'
```

For local source directories:

```bash
scripts/build_wheel_manylinux.sh /home/yzw/keda-wheel-build /work/src/pkg/pkg-1.0.0 ''
```

After repair, run a smoke install check with `--only-binary=:all:`.

## Known Build Order

For the Keda-style stack, use this order:

1. `numpy`
2. `scipy`
3. `pandas`
4. `scikit-learn`
5. `statsmodels`
6. `matplotlib`
7. `psutil`
8. `lightgbm`
9. `pmdarima`
10. `tsdownsample`
11. full install check for the complete requirements, excluding only confirmed platform-inapplicable or separately-decided packages.

Read `references/package-notes.md` before building these packages again.

## Package-Specific Rules

- `numpy==1.26.4`: if lpypi lacks the exact wheel, build from sdist; repair with OpenBLAS visible via `LD_LIBRARY_PATH=/usr/lib64:/lib64`.
- `scipy==1.11.4`: install OpenBLAS/LAPACK development packages and set `PATH=/opt/python/cp311-cp311/bin:$PATH`; repair in a container that can locate BLAS/LAPACK runtime libraries.
- `matplotlib==3.7.5`: prefer system freetype/libpng; qhull may need preseeded source if network fetches are fragile.
- `pmdarima==2.0.4`: if `distutils.msvccompiler` errors occur, use `SETUPTOOLS_USE_DISTUTILS=stdlib` and older setuptools such as `59.8.0` for the build.
- `tsdownsample==0.1.4.1`: install Rust/Cargo. If `argminmax` fails on stable Rust because nightly features are gated, `RUSTC_BOOTSTRAP=1` can build it; record this as a build-risk note.
- `lightgbm==4.6.0`: build with CMake/Ninja/OpenMP. x86 SIMD probe failures are not fatal on LoongArch if CMake disables those paths.
- `kaleido==0.2.1`: do not promise normal compilation. It binds Chromium `88.0.4324.150`, whose upstream GN/toolchain files do not include LoongArch64 support. Prefer `kaleido>=1.x` only if an external LoongArch Chrome/Chromium runtime is available and the project does not use old `kaleido.scopes.plotly.PlotlyScope` APIs.

## Validation

Always validate both installation and runtime entry points:

- import package and print `__version__`;
- run a tiny numerical/API operation, not just import;
- for Plotly/Kaleido, run `fig.to_image(format='png')` if image export matters;
- confirm no Docker containers are left running with `docker ps`.

Keep final answers explicit about:

- what was built from source;
- what came from lpypi/PyPI as wheels;
- which packages are excluded or platform-inapplicable;
- which packages install but require external runtime components.
