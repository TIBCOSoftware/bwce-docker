# TIBCO BusinessWorks™ Container Edition — Design-Time Builder Docker Image

A Docker image that runs TIBCO BusinessWorks™ Maven goals (`bw6:bwear`, `bw6:bwmodule`,
`bw6:bwtest`) and the `bwdesign` design-time console **headlessly**, so CI agents and developers
can build BW artifacts without installing TIBCO BusinessWorks Container Edition on the host.

Drop your installer ZIPs into the folders below and run `docker build`. There are no version
numbers to edit, no `ARG` overrides to pass, and no filename conventions to learn — the Dockerfile
discovers whatever you place in each folder.

> **This is a build-time image, not a runtime image.** The BusinessWorks runtime engine is
> deliberately excluded, so this image *produces* EAR files but cannot *run* them. To run a
> deployed application, use the BWCE runtime image from the
> [master](https://github.com/TIBCOSoftware/bwce-docker/tree/master) branch.

## Version

This branch targets **TIBCO BusinessWorks Container Edition 6.12.0**. The image installs
design-time components and the BW Maven plugin only.

## Prerequisites

* Access to [TIBCO® eDelivery](https://edelivery.tibco.com) to download the installer artifacts
* [Docker](https://docs.docker.com/engine/installation/) with **BuildKit enabled**
* Roughly 20 GB of free disk space for the build
* An `linux/amd64` build target — the Dockerfile pins `--platform=linux/amd64`, so on Apple
  Silicon the build runs under emulation and is noticeably slower

BuildKit is required, not optional: the Dockerfile uses the `# syntax=docker/dockerfile:1`
directive, `RUN --mount=type=bind` and heredoc `RUN` blocks. BuildKit is the default on current
Docker Desktop and Docker Engine; on an older classic builder, export `DOCKER_BUILDKIT=1`.

## Repository layout

```
bwce-docker/
├── Dockerfile
├── response.silent          # installer answer file for the base install
├── base/                    # BWCE Linux GA installer ZIP           (REQUIRED)
├── hotfix/                  # BWCE base hotfix ZIP                  (optional)
├── plugins/                 # plug-in GA installer ZIPs             (optional)
├── plugins-hotfix/          # plug-in hotfix ZIPs                   (optional)
└── custom-jars/             # *.jar + matching *-pom.xml pairs      (optional)
```

Each folder has its own README describing exactly what belongs in it and how it is consumed:
[base](base/README.md) · [hotfix](hotfix/README.md) · [plugins](plugins/README.md) ·
[plugins-hotfix](plugins-hotfix/README.md) · [custom-jars](custom-jars/README.md)

Only `base/` is mandatory. Every other folder may be left empty — the build logs that it is
skipping the step and continues. **All five folders must exist**, however, even when empty: they
are BuildKit bind-mount sources, and a missing source directory fails the build before anything
runs.

## Download the artifacts

From [TIBCO® eDelivery](https://edelivery.tibco.com), download the **Linux x86-64** installers you
need and place them as follows:

| Artifact | Folder |
|---|---|
| `TIB_bwce_6.12.0_linux26gl25_x86_64.zip` | `base/` |
| `TIB_bwce_6.12.0_HF-003_linux26gl25_x86_64.zip` | `hotfix/` |
| Plug-in GA ZIPs, e.g. Kafka, AWS S3 | `plugins/` |
| Plug-in hotfix ZIPs | `plugins-hotfix/` |

Do not rename the hotfix ZIP — the hotfix number is parsed out of its filename. See
[hotfix/README.md](hotfix/README.md).

Installer ZIPs are multi-GB and license-restricted. Keep them out of version control.

## Build the image

```sh
docker build -t tibco/bwce-builder:6.12.0-HF3 .
```

Because the set of installed plug-ins is fixed at build time, encode it in the tag so consumers
know what they are getting:

```sh
docker build -t tibco/bwce-builder:6.12.0-HF3-kafka-s3 .
```

Install order is enforced by the Dockerfile:

**base GA → base HF → plug-in GAs (alphabetical) → plug-in HFs (alphabetical)**

Plug-ins are installed in shell glob order. If one must precede another, prefix the filenames
(`01-…`, `02-…`).

## What ends up in the image

| | |
|---|---|
| Base image | `maven:3.9.16-eclipse-temurin-17-noble` (Maven 3.9, Temurin JDK 17) |
| `TIBCO_HOME` | `/opt/tibco` |
| `BW_HOME` | `/opt/tibco/bw/6.12` |
| BW features | Design **yes** · Maven plugin **yes** · Runtime **no** |
| Maven repository | `/home/bwce/.m2/repository`, pre-seeded with `bw6-maven-plugin` and its dependencies |
| User | non-root `bwce` (uid/gid 2001) |
| Working directory | `/workspace` |
| Default command | `mvn --version` |

The feature selection comes from [`response.silent`](response.silent) — the answer file that lets
the TIBCO Universal Installer run unattended. Its three `feature_*` entries
(`feature_Design_BW=true`, `feature_Runtime_BW=false`, `feature_Maven Plugin_BW=true`) are what
make this a build-only image.

Because the Maven repository is pre-seeded during the build, `mvn bw6:*` goals resolve offline —
no download from an external repository at run time.

## Using the image

### Verify the image

```sh
docker run --rm tibco/bwce-builder:6.12.0-HF3
```

Prints the Maven and Java versions and exits.

### Build an EAR or a module JAR

Mount the **workspace root**, not the individual project folder, and point Maven at the POM:

```sh
docker run --rm \
  -v "/path/to/workspace:/workspace" \
  tibco/bwce-builder:6.12.0-HF3 \
  mvn -f MyApp.application/pom.xml bw6:bwear
```

```sh
docker run --rm \
  -v "/path/to/workspace:/workspace" \
  tibco/bwce-builder:6.12.0-HF3 \
  mvn -f MyApp.module/pom.xml bw6:bwmodule
```

Application POMs reference their parent POM by relative path (`../MyApp.parent`). Mounting only
the application subfolder hides the parent and Maven fails with *Non-resolvable parent POM*.

### Run BW unit tests

```sh
docker run --rm \
  -v "/path/to/workspace:/workspace" \
  tibco/bwce-builder:6.12.0-HF3 \
  mvn -f MyApp.application/pom.xml bw6:bwtest
```

A project with no BWT files exits cleanly rather than failing.

### bwdesign

`bwdesign` is an interactive Eclipse RCP shell. It has no `-e`/`-c` flag — commands are fed on
**stdin**, one per line, and the last one must be `exit` or the container hangs waiting for input.
The `/usr/local/bin/bwdesign` wrapper supplies the virtual display and D-Bus session for you.

```sh
docker run --rm \
  -v "/path/to/workspace:/bwworkspace" \
  -v "/path/to/output:/output" \
  tibco/bwce-builder:6.12.0-HF3 \
  sh -c "printf 'system:import /bwworkspace/MyApp.module\nsystem:import /bwworkspace/MyApp.application\nsystem:export MyApp.application /output -ear\nexit\n' | bwdesign -data /tmp/ws"
```

Import the module before the application, or the export fails on unresolved references.

For CI, keep the commands in a file checked into your repository:

```sh
docker run --rm \
  -v "/path/to/workspace:/bwworkspace" \
  -v "/path/to/output:/output" \
  -v "/path/to/bwdesign-commands.txt:/commands.txt" \
  tibco/bwce-builder:6.12.0-HF3 \
  sh -c "bwdesign -data /tmp/ws < /commands.txt"
```

Useful commands: `edition`, `help`, `help <command>`, `system:import`, `system:validate`,
`system:export`, `generate_manifest_json`, `exit`.

`/tmp/ws` is the ephemeral Eclipse workspace, created fresh on every run. Do not mount anything
over it.

### Jenkins

```groovy
stage('Build EAR') {
    steps {
        sh """
            docker run --rm \
              -v "\${WORKSPACE}:/workspace" \
              tibco/bwce-builder:6.12.0-HF3 \
              mvn -f MyApp.application/pom.xml clean package
        """
    }
}
```

Parallel stages are safe. Each `docker run` is fully isolated — its own workspace, its own Xvfb
display, its own D-Bus session — so several containers can export different EARs simultaneously.

## Volume mount reference

| Container path | Purpose |
|---|---|
| `/workspace` | Maven project root, for `mvn` goals. Also the default `WORKDIR`. |
| `/bwworkspace` | Source workspace containing BW projects, for `bwdesign` imports. |
| `/output` | Destination for exported EARs and manifests. |

## How the Dockerfile works

A few decisions in the Dockerfile are non-obvious and worth knowing before you change it.

**Everything installs in a single `RUN`.** The TIBCO Universal Installer writes a machine-bound
VPD product registry that links the base install, hotfixes and plug-ins together. Splitting these
across separate `RUN` instructions puts them in different layers with different identities, and
the hotfix installer then fails to find the base installation.

**Installer ZIPs are bind-mounted, never copied.** `RUN --mount=type=bind` makes each folder
available during the build without writing it into a layer, which the Dockerfile notes avoids
roughly 2.3 GB of permanent image weight that a `COPY` would leave behind in the history even
after a later `rm -rf`.

**Xvfb is mandatory.** The Universal Installer is a GUI application even under `-silent`, and
`bwdesign` is an SWT/GTK Eclipse application. Both die without a display, hence the `xvfb`,
`dbus-x11` and GTK/X11 library dependencies.

**Hotfix and plug-in hotfix ZIPs have no installer binary.** The one the base install leaves at
`$TIBCO_HOME/tools/universal_installer/` is copied in and reused, then removed during cleanup at
the end of the same `RUN`.

**Plug-in response files are patched in place.** Each plug-in ZIP ships its own
`TIBCOUniversalInstaller*.silent`; `installationRoot`, `environmentName` and `configDirectoryRoot`
are rewritten with `sed` so the plug-in registers against this image's `TIBCO_HOME` rather than a
vendor default.

**`install.sh` is CRLF-stripped.** BW 6.12 ships `$BW_HOME/maven/install.sh` with Windows line
endings, which will not execute on Linux without `sed -i 's/\r$//'`.

**Install-time artifacts are deleted** — `p2repos`, `p2director`, `universal_installer`,
`thirdpartyDownload`, `release_notes`, `_installInfo`, `backup`, `samples` and `doc` — and the
final `chown` runs inside the same `RUN`, avoiding a duplicate multi-GB layer.

**`$BW_HOME/bin/bwdesign` is shimmed (BWCE-11709).** The `bw6-maven-plugin` `bwdesignUtility`
goal spawns `$BW_HOME/bin/bwdesign` by absolute path, bypassing `/usr/local/bin/bwdesign`
entirely. With no `DISPLAY` it dies inside `gtk_init_check()`. The real launcher is renamed to
`bwdesign.bin` and replaced with a shim that supplies a virtual display only when one is not
already present.

**The image runs as non-root.** All processes run as `bwce` (uid/gid 2001), since most enterprise
Kubernetes clusters reject root containers.

## Troubleshooting

| Symptom | Cause |
|---|---|
| `ERROR: No ZIP found in base/` | `base/` is empty. It is the one required folder. |
| Build fails while parsing the hotfix filename | The ZIP in `hotfix/` has no `HF-<number>` token in its name. The build runs under `set -eo pipefail`, so this is a hard failure with no fallback. |
| `unknown flag: mount` or a syntax error on `RUN --mount` | BuildKit is not enabled. Set `DOCKER_BUILDKIT=1`. |
| Bind-mount source not found | One of the five folders is missing. They must all exist, even when empty. |
| `Non-resolvable parent POM` | You mounted the application subfolder instead of the workspace root. |
| Container hangs after a `bwdesign` run | The command list did not end with `exit`. |
| `bwdesign` takes 30–60 seconds to start | Expected — Eclipse OSGi bundle resolution. It does not affect `mvn` builds. |
| A plug-in palette is missing at build time | Plug-ins are fixed at image build time. Add the ZIP to `plugins/` and rebuild. |

If you add a `.dockerignore` to this branch, **do not exclude `*.md`**. The installer folders are
tracked in git by their README alone; filtering the READMEs out of the build context removes the
directories along with them and the bind mounts fail.

## Limitations

* **No BusinessWorks runtime.** The image builds EARs; it cannot execute them.
* **Plug-ins are fixed at image build time.** Adding one requires a rebuild. Reflect the contents
  in the image tag.
* **`linux/amd64` only.** The TIBCO installers are x86-64 Linux binaries.
* **`bwdesign` startup cost** of 30–60 seconds per container run is inherent to Eclipse RCP and
  cannot be tuned away.

## License

These Docker scripts are released under a
[3-clause BSD-type](https://github.com/TIBCOSoftware/bwce-docker/blob/master/License.md) license.
Review the license before using or downloading these scripts. The TIBCO BusinessWorks Container
Edition installers themselves are licensed separately and are not distributed with this
repository.

TIBCO, ActiveMatrix, ActiveMatrix BusinessWorks and TIBCO BusinessWorks are trademarks or
registered trademarks of TIBCO Software Inc. in the United States and/or other countries.

Docker is a trademark or registered trademark of Docker, Inc. in the United States and/or other
countries.

OSGi is a trademark or a registered trademark of the OSGi Alliance in the United States, other
countries, or both.
