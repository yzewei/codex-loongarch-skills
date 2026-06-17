# Codex LoongArch Skills

个人 Codex skills 仓库，主要沉淀 LoongArch 机器上的兼容性测试、Docker 运行、Python wheel 构建和项目适配流程。

## Skills

### `box64-docker-amd64`

用途：在 LoongArch 主机上运行、诊断和记录 `linux/amd64` Docker 镜像，使用显式挂载的静态 Box64，而不是修改宿主机全局 `binfmt_misc`。

适用场景：

- 商业或闭源 x86_64 容器兼容性测试
- 将镜像 Entrypoint/Cmd 转换为 Box64 调用
- 采集 Box64 trace 日志
- 维护镜像兼容性矩阵
- 避免破坏宿主机已有的 x86_64/LATX 运行方式

主要内容：

- `scripts/box64-docker-run.sh`
- `references/host-layout.md`
- `references/image-matrix.md`

### `loongarch-python-wheels`

用途：在 LoongArch64 上审计、编译、修复和验证 Python 3.11 依赖栈，重点面向 `glibc >= 2.38` 的 `manylinux_2_38_loongarch64` wheel 产物。

适用场景：

- Python 3.11 / LoongArch64 科学计算、机器学习、Dash/Plotly 项目适配
- 使用 `ghcr.io/loong64/manylinux_2_38_loongarch64` 构建 wheel
- 使用 `lpypi.loongnix.cn` 和 PyPI fallback 审计依赖
- 编译 `numpy/scipy/pandas/scikit-learn/matplotlib/lightgbm/pmdarima/tsdownsample` 等架构相关包
- 判断 `pywin32`、`kaleido` 这类平台或运行时依赖问题

主要内容：

- `scripts/prepare_workspace.sh`
- `scripts/build_wheel_manylinux.sh`
- `scripts/repair_wheel_manylinux.sh`
- `scripts/full_install_check.sh`
- `references/package-notes.md`

## Install

把仓库克隆到任意目录后，将需要的 skill 复制到 Codex skills 目录：

```bash
git clone git@github.com:yzewei/codex-loongarch-skills.git
mkdir -p ~/.codex/skills
cp -a codex-loongarch-skills/box64-docker-amd64 ~/.codex/skills/
cp -a codex-loongarch-skills/loongarch-python-wheels ~/.codex/skills/
```

或者一次同步仓库中的全部 skill：

```bash
mkdir -p ~/.codex/skills
find codex-loongarch-skills -mindepth 1 -maxdepth 1 -type d \
  ! -name .git -exec cp -a {} ~/.codex/skills/ \;
```

## Update This Repo From Local Skills

在维护机器上，如果 `~/.codex/skills` 里的 skill 有更新，可以同步回本仓库：

```bash
cp -a ~/.codex/skills/box64-docker-amd64 ./
cp -a ~/.codex/skills/loongarch-python-wheels ./
git status
git add .
git commit -m "Update personal Codex skills"
git push
```

新增 skill 时，直接把新的 skill 目录复制到仓库根目录，并在本 README 的 `Skills` 小节补充说明。

## Notes

- 这些 skill 面向 LoongArch/龙芯环境，脚本默认偏向 Linux、Docker、manylinux 和本地挂载产物目录。
- 对涉及构建、下载、Docker、远程仓库的操作，仍应按实际机器权限和网络环境确认。
- 仓库不保存大型构建产物、wheelhouse、Docker 镜像或项目私有数据。
