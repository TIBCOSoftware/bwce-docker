# plugins/ — BW plugin GA installers (optional)

Drop **one or more** plugin GA installer ZIPs here, for example:

```
TIB_bwpluginkafka_6.8.2_linux26gl25_x86_64.zip
TIB_bwplugins3_6.7.0_linux26gl25_x86_64.zip
```

Leave the folder empty to skip this step — the build logs `plugins/ is empty — skipping.`
and carries on.

## Install order

Plugins are installed by shell glob expansion, which is **alphabetical**. If one plugin must be
installed before another, prefix the filenames to force the order:

```
01-TIB_bwplugins3_6.7.0_....zip
02-TIB_bwpluginkafka_6.8.2_....zip
```

All plugin GAs are installed **before** anything in `../plugins-hotfix/`.

## How it is used

Each ZIP ships its own installer binary and its own `TIBCOUniversalInstaller*.silent` response
file. Before running, three entries in that response file are rewritten with `sed` so the plugin
lands in the image's TIBCO_HOME rather than the vendor default:

| Entry | Rewritten to |
|---|---|
| `installationRoot` | `/opt/tibco` |
| `environmentName` | `TIBCO-HOME` |
| `configDirectoryRoot` | `/opt/tibco` |

Without this the plugin installs to the wrong directory and is not registered against the base
install.

## Plugins are fixed at image build time

Only plugins present here during `docker build` are available in the resulting image. To add one
later you must rebuild. Reflect the contents in the image tag so consumers know what they are
getting, e.g. `tibco/bwce-builder:6.12.0-HF3-kafka-s3`.

## Do not commit installer ZIPs

Consumed via a BuildKit bind mount; never becomes an image layer. Keep `*.zip` out of git.
