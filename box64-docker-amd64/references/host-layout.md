# Host Layout

## Known Configuration

- Host architecture: LoongArch64.
- Host x86_64 binfmt handler: `/usr/bin/latx-x86_64`.
- Do not replace that handler globally because host x86_64 applications such
  as Codex may be statically linked and fail under Box64.
- Static trace Box64:
  `/home/yzw/python-trans/box64-up/build-static-trace-v2/box64`
- Expected version output contains both `with Dynarec` and `with trace`.
- Docker requires root or membership in the `docker` group on this host.

## Verified Baseline

The following command reached an interactive Bash prompt:

```bash
docker run --rm -it --platform linux/amd64 \
  --entrypoint /opt/box64 \
  -v /home/yzw/python-trans/box64-up/build-static-trace-v2/box64:/opt/box64:ro \
  -e BOX64_LOG=1 \
  debian:bookworm-slim \
  /bin/bash
```

This proves image pull, amd64 selection, static Box64 startup, guest x86_64
loader resolution, and an interactive dynamically linked Bash process.

It does not prove that arbitrary static guest binaries or complex services
work.

## Build Note

Upstream CMake forces `HAVE_TRACE` off inside the `STATICBUILD` branch. The
local source was adjusted before configuring:

```bash
cmake -S . -B build-static-trace-v2 \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DLARCH64_DYNAREC=ON \
  -DSTATICBUILD=ON \
  -DHAVE_TRACE=ON
cmake --build build-static-trace-v2 -j"$(nproc)"
```

Validate after every rebuild:

```bash
file build-static-trace-v2/box64
build-static-trace-v2/box64 --version
```
