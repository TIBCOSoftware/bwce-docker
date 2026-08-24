# base/ — BWCE Linux GA installer (REQUIRED)

Drop **exactly one** BWCE Linux installer ZIP here, for example:

```
TIB_bwce_6.12.0_linux26gl25_x86_64.zip
```

## How it is used

The Dockerfile picks the first `*.zip` in this folder (`ls base/*.zip | head -1`) and installs it
with the TIBCO Universal Installer in silent mode, driven by `../response.silent`:

```
xvfb-run TIBCOUniversalInstaller-lnx-x86-64.bin -silent -V responseFile=/tmp/response.silent
```

This is the only **required** folder. If it contains no ZIP the build stops immediately with:

```
ERROR: No ZIP found in base/ — at least one BWCE Linux installer ZIP is required.
```

## Requirements

- **One ZIP only.** If more than one is present, the alphabetically first is used and the rest
  are silently ignored.
- **The ZIP must extract flat** — `TIBCOUniversalInstaller-lnx-x86-64.bin` has to sit at the top
  level of the archive, not inside a subfolder.
- **Linux x86-64 installer.** The image is built `--platform=linux/amd64`; a Windows or macOS
  installer ZIP will not work.

## Do not commit installer ZIPs

These archives are multi-GB and license-restricted. They are consumed via a BuildKit bind mount,
so they never become an image layer — but they must be present on disk at build time.
Keep `*.zip` out of git.
