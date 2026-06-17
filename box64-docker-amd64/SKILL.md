---
name: box64-docker-amd64
description: Run, diagnose, and document linux/amd64 Docker images on a LoongArch host with an explicitly mounted static Box64 binary. Use for commercial or closed-source container compatibility tests, converting image entrypoints to Box64 invocations, collecting trace logs, maintaining a compatibility matrix, and avoiding host-wide binfmt changes that would break existing x86_64 programs.
---

# Box64 Docker AMD64

Use explicit `--entrypoint /opt/box64`. Do not replace the host's x86_64
`binfmt_misc` handler: the host uses LATX and some statically linked x86_64
programs do not run under Box64.

## Workflow

1. Read `references/host-layout.md`.
2. Verify the configured Box64 binary is static and reports `with trace`.
3. Pull the image explicitly for `linux/amd64`.
4. Inspect its original Entrypoint and Cmd before overriding them.
5. Start with a version/help command or a shell.
6. Test normal startup only after the binary-level smoke test passes.
7. Record the exact image digest, command, result, and first failure.
8. Read `references/image-matrix.md` for the current test order and commands.

## Teaching Collaboration

Treat emulator and wrapper debugging as pair work with the developer:

1. Separate confirmed facts, inferences, and open hypotheses before proposing
   a fix.
2. Explain the guest call, guest ABI, host target, Box64 wrapper declaration,
   and expected validation before editing non-trivial code.
3. Make one small, reviewable change at a time and wait for developer
   agreement before each non-trivial implementation step.
4. After each change, walk through the relevant call path and command output.
5. Do not consider the task complete until the developer can explain the root
   cause, test the fix, and continue or revert the work without the current
   Codex session.

Use `scripts/box64-docker-run.sh` for direct guest ELF or shell execution:

```bash
scripts/box64-docker-run.sh -- IMAGE GUEST [ARG...]
```

Pass ordinary Docker options before `--`:

```bash
scripts/box64-docker-run.sh \
  -e TS3SERVER_LICENSE=accept \
  -p 9987:9987/udp \
  -- teamspeak:latest /bin/sh /opt/ts3server/entrypoint.sh ts3server
```

Set `BOX64_BIN`, `BOX64_LOG`, `BOX64_TRACE`, or `BOX64_TRACE_FILE` when
needed. Set `BOX64_DOCKER_USE_SUDO=1` when Docker requires root.

## Entrypoint Conversion

Inspect the image:

```bash
docker image inspect IMAGE \
  --format 'entrypoint={{json .Config.Entrypoint}} cmd={{json .Config.Cmd}}'
```

Convert based on its type:

- ELF entrypoint: invoke that path directly through Box64.
- Shell script: invoke the image's x86_64 shell through Box64, then pass the
  script path and original arguments.
- Missing shell or distroless image: invoke the application ELF directly.

Do not mount LoongArch loaders or set host `LD_LIBRARY_PATH` for the static
Box64 build. The image must still contain the x86_64 loader and guest libraries
required by its application.

## Diagnosis

Keep the first run small:

```bash
BOX64_LOG=1 scripts/box64-docker-run.sh -- IMAGE /path/to/app --version
```

Enable instruction trace only around a narrow failing command:

```bash
BOX64_TRACE=1 \
BOX64_TRACE_FILE=/tmp/box64-trace-%pid.txt \
scripts/box64-docker-run.sh -- IMAGE /path/to/app ARG
```

Treat these separately:

- Image pull or platform failure: registry/manifest issue.
- `File is not an ELF` or missing path: incorrect converted entrypoint.
- Missing x86_64 loader/library: guest image dependency issue.
- Box64 signal with x64 PC/register dump: emulator compatibility issue.
- Child command fails from a shell script: inspect the child ELF and rerun it
  directly through Box64.

Never claim an image works from manifest inspection alone. Record `manifest
verified`, `binary smoke passed`, and `service startup passed` as distinct
states.
