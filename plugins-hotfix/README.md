# plugins-hotfix/ — BW plugin hotfix installers (optional)

Drop **one or more** plugin hotfix ZIPs here, for example:

```
TIB_bwpluginkafka_6.8.2_HF-001_linux26gl25_x86_64.zip
```

Leave the folder empty to skip this step — the build logs
`plugins-hotfix/ is empty — skipping.` and carries on.

## Install order

These are installed **after every GA plugin in `../plugins/`** has been installed, in
alphabetical order among themselves. A plugin hotfix placed here without its matching GA in
`../plugins/` will not apply cleanly.

## How it is used

Like base hotfixes, plugin hotfix ZIPs do not ship an installer binary — the one left by the base
install at `$TIBCO_HOME/tools/universal_installer/` is copied in and reused. The hotfix's own
`TIBCOUniversalInstaller*.silent` is then patched with `sed`:

| Entry | Rewritten to |
|---|---|
| `installationRoot` | `/opt/tibco` |
| `environmentName` | `TIBCO-HOME` |
| `configDirectoryRoot` | `/opt/tibco` |

Note: unlike `../hotfix/`, no `HF-<number>` feature entries are injected here, so there is no
filename constraint on these ZIPs.

## Do not commit installer ZIPs

Consumed via a BuildKit bind mount; never becomes an image layer. Keep `*.zip` out of git.
