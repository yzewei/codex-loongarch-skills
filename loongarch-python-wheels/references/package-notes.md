# Package Notes

## Keda Case Results

Target environment:

- Python ABI: `cp311`
- Docker image: `ghcr.io/loong64/manylinux_2_38_loongarch64:2026.06.04-1`
- Container Python: `/opt/python/cp311-cp311/bin/python`
- Host workspace example: `/home/yzw/keda-wheel-build`

Built and repaired successfully:

- `numpy==1.26.4`: manylinux_2_38; lpypi did not provide exact cp311 LoongArch wheel at the time of testing.
- `psutil==7.0.0`: abi3, eligible for manylinux_2_36 and manylinux_2_38.
- `matplotlib==3.7.5`: manylinux_2_38; used system freetype/libpng and preseeded qhull.
- `scipy==1.11.4`: manylinux_2_38; required OpenBLAS/LAPACK and auditwheel repair with runtime libs visible.
- `pandas==2.1.4`: manylinux_2_36 + manylinux_2_38.
- `scikit-learn==1.4.2`: manylinux_2_38; OpenMP/libgomp included by auditwheel.
- `statsmodels==0.14.4`: manylinux_2_36 + manylinux_2_38.
- `lightgbm==4.6.0`: py3-none manylinux_2_38 wheel containing native library.
- `pmdarima==2.0.4`: manylinux_2_36 + manylinux_2_38; used stdlib distutils workaround.
- `tsdownsample==0.1.4.1`: manylinux_2_36 + manylinux_2_38; built with Rust/Cargo and `RUSTC_BOOTSTRAP=1`.

Installed successfully from existing binary wheels or pure Python wheels:

- `torch==2.7.1`
- `torchvision==0.22.1`
- `llvmlite==0.44.0`
- `numba==0.61.2`
- `orjson==3.10.18`
- `rpds-py==0.25.1`
- `xxhash==3.5.0`
- `contourpy==1.3.2`
- `kiwisolver==1.4.8`
- and pure Python packages such as `dash`, `plotly`, `pycaret`, `sktime`, `tbats`, `yellowbrick`.

## pywin32

`pywin32==310` is Windows-only. On Linux/LoongArch, remove it from deployment requirements or guard it with a platform marker:

```text
pywin32==310; platform_system == "Windows"
```

## Kaleido

`kaleido==0.2.1` includes a native Kaleido executable built against Chromium. Its upstream scripts use Chromium `88.0.4324.150`. That Chromium version predates upstream LoongArch64 support, and Kaleido's Linux scripts only provide `x64` and `arm64` GN args and packaging branches.

`kaleido>=1.x` installs as Python-level packages on LoongArch, but Plotly's static image export requires an external Chrome/Chromium runtime. Validate with:

```python
import plotly.graph_objects as go
fig = go.Figure(data=[go.Scatter(y=[1, 3, 2])])
fig.to_image(format="png")
```

If this fails with a browser-not-found error, install a LoongArch Chrome/Chromium and set `BROWSER_PATH` if needed.
