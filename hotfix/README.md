# hotfix/ — BWCE base hotfix installer (optional)

Drop **at most one** BWCE base hotfix ZIP here, for example:

```
TIB_bwce_6.12.0_HF-003_linux26gl25_x86_64.zip
```

Leave the folder empty to skip the hotfix step — the build logs
`hotfix/ is empty — skipping HF install.` and carries on.

## Filename requirement — important

The Dockerfile derives the hotfix number from the **filename**:

```sh
HF_NUM=$(basename "$HF_ZIP" | grep -oE 'HF-[0-9]+' | grep -oE '[0-9]+' | sed 's/^0*//')
```

It then injects the matching feature entries into the hotfix response file:

```xml
<entry key="feature_Design Hotfix 3_BW">true</entry>
<entry key="feature_Runtime Hotfix 3_BW">false</entry>
```

So the filename **must** contain `HF-<number>` (e.g. `HF-003`, `HF-12`). Leading zeros are
stripped, so `HF-003` becomes `3`. Because the build runs under `set -eo pipefail`, a filename
without an `HF-<number>` token makes the `grep` fail and **the whole build fails** — it does not
fall back to a default. Do not rename the vendor ZIP.

## How it is used

Hotfix ZIPs do not ship their own installer binary, so the one the base install left at
`$TIBCO_HOME/tools/universal_installer/` is copied in and reused. The hotfix's own
`TIBCOUniversalInstaller*.silent` is used as the response file, patched as shown above.

The hotfix runs in the **same `RUN` layer** as the base install — the TIBCO VPD product registry
is machine/layer bound, so a hotfix in a separate layer would not find the base installation.

## Do not commit installer ZIPs

Consumed via a BuildKit bind mount; never becomes an image layer. Keep `*.zip` out of git.
