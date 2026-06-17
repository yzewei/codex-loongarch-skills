# Commercial Image Test Matrix

Use versioned tags or digests after initial exploration. `latest` is only for
the first compatibility probe.

## States

- `manifest verified`: amd64 image exists and metadata was inspected.
- `binary smoke passed`: proprietary application printed version/help.
- `service startup passed`: application stayed up and its health/API/port was
  checked.

## Order

### 0. Debian Baseline

Status: binary smoke passed.

```bash
scripts/box64-docker-run.sh -- debian:bookworm-slim /bin/bash
```

### 1. TeamSpeak Server

Why first: Docker Official Image, proprietary server, amd64-only, about 14 MB
compressed, and exercises threads, networking, SQLite, and a long-running
process.

Status on 2026-06-12: manifest verified; Box64 started Alpine BusyBox and the
entrypoint, but service startup failed during BusyBox relocation. The native
`libc.musl-x86_64.so.1` wrapper did not provide DNS, network database, swap,
`pivot_root`, and `crypt` symbols expected by BusyBox. Test emulated musl before
adding wrappers:

```bash
BOX64_EMULATED_LIBS=libc.musl-x86_64.so.1 \
scripts/box64-docker-run.sh \
  -e TS3SERVER_LICENSE=accept \
  -p 9987:9987/udp \
  -p 10011:10011 \
  -p 30033:30033 \
  -- teamspeak:latest \
  /bin/sh /opt/ts3server/entrypoint.sh ts3server
```

If this passes, classify the original failure as a musl native-wrapper gap,
not a dynarec or TeamSpeak failure.

```bash
docker pull --platform linux/amd64 teamspeak:latest
docker image inspect teamspeak:latest \
  --format 'entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}}'
```

Run its shell entrypoint through the image's x86_64 shell:

```bash
scripts/box64-docker-run.sh \
  -e TS3SERVER_LICENSE=accept \
  -p 9987:9987/udp \
  -p 10011:10011 \
  -p 30033:30033 \
  -- teamspeak:latest \
  /bin/sh /opt/ts3server/entrypoint.sh ts3server
```

If the inspected path differs, use the inspected path.

### 2. ngrok Agent

Why second: common proprietary CLI/agent with TLS, DNS, networking, and a
simple `version` smoke test. The Debian image is preferred over Alpine during
initial diagnosis.

Status: amd64 manifest verified on 2026-06-12. Runtime not yet tested.

```bash
docker pull --platform linux/amd64 ngrok/ngrok:latest
docker image inspect ngrok/ngrok:latest \
  --format 'entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}}'
```

The binary is installed in a Nix store path. Resolve it through the image's
configured `PATH` instead of hard-coding `/bin/ngrok`:

```bash
scripts/box64-docker-run.sh \
  -- ngrok/ngrok:latest /bin/sh -lc 'command -v ngrok && ngrok version'
```

### 3. Splunk Universal Forwarder

Why third: smaller Splunk workload while retaining proprietary Splunk
binaries, OpenSSL, process supervision, and configuration scripts.

Status: amd64 manifest verified on 2026-06-12. Runtime not yet tested.

First inspect paths, then smoke-test the binary directly:

```bash
scripts/box64-docker-run.sh \
  -- splunk/universalforwarder:latest \
  /opt/splunkforwarder/bin/splunk version
```

Only after that passes, convert the original shell entrypoint and supply the
required license/password environment.

### 4. Microsoft SQL Server

Why fourth: proprietary, CPU/memory intensive, many threads, shared memory,
signals, networking, and substantial runtime initialization.

Use a fixed supported tag from Microsoft documentation, not an unreviewed
`latest` tag. Invoke `/opt/mssql/bin/sqlservr` directly through Box64 and set
the documented license/password variables.

### 5. Splunk Enterprise

Why last: large image and a complex Ansible/shell startup chain with many
fork/exec operations. It is a poor first diagnostic target.

Smoke-test `/opt/splunk/bin/splunk version` before running
`/sbin/entrypoint.sh start-service`. Keep `BOX64_LOG=0` for normal startup and
enable trace only for a minimal reproducer.

## Result Record

For every test record:

```text
date:
host kernel:
box64 commit/build:
image tag:
amd64 digest:
original entrypoint/cmd:
box64 command:
result state:
exit code:
first error:
trace/log path:
```
