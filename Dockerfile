# syntax=docker/dockerfile:1
# BWCE Builder Image — Generic Linux Installer
#
# Just drop your installer ZIPs into the correct folder and run docker build.
# No version numbers, no ARG overrides, no naming conventions required.
#
# Directory structure:
#   base/             ← one ZIP: the main BWCE Linux installer (required)
#   hotfix/           ← one ZIP: the BWCE base HF installer (optional)
#   plugins/          ← one or more ZIPs: plugin GA installers (optional)
#   plugins-hotfix/   ← one or more ZIPs: plugin HF installers (optional, installed after all plugin GAs)
#   custom-jars/      ← *.jar + matching *-pom.xml: extra Maven JARs (optional)
#
# Install order: base GA → base HF → plugin GAs (alphabetical) → plugin HFs (alphabetical)
#
# Build:
#   docker build -t tibco/bwce-builder:latest .
#
# Usage:
#   docker run --rm -v /path/to/project:/workspace tibco/bwce-builder:latest mvn clean package
#   docker run --rm tibco/bwce-builder:latest sh -c "printf 'help\nexit\n' | bwdesign -data /tmp/ws"

FROM --platform=linux/amd64 maven:3.9.16-eclipse-temurin-17-noble

LABEL org.opencontainers.image.title="BWCE Builder" \
      org.opencontainers.image.description="BW 6.12 design-time image for CI Maven goals" \
      org.opencontainers.image.vendor="TIBCO"

ENV TIBCO_HOME=/opt/tibco
ENV BW_HOME=/opt/tibco/bw/6.12
ENV MAVEN_CONFIG=/home/bwce/.m2
ARG TEMP_INST_DIR=/tmp/install

RUN mkdir -p ${TEMP_INST_DIR} ${TIBCO_HOME}/_installInfo

RUN apt-get update && apt-get install -y --no-install-recommends \
      unzip \
      xvfb \
      dbus-x11 \
      libgtk-3-0 \
      libcairo2 \
      libpango-1.0-0 \
      libpangocairo-1.0-0 \
      libgdk-pixbuf-2.0-0 \
      libatk1.0-0 \
      libx11-6 \
      libxext6 \
      libxrender1 \
      libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# Create bwce user before the install RUN so chown can run inside the same layer
RUN groupadd -g 2001 bwce && \
    useradd -m -d /home/bwce -r -u 2001 -g bwce bwce && \
    mkdir -p /home/bwce/.m2/repository

# All subsequent RUN steps use bash with errexit + pipefail so pipeline failures
# (e.g. ls … | head -1) are never silently swallowed.
SHELL ["/bin/bash", "-eo", "pipefail", "-c"]

# ── Install everything in ONE RUN using bind mounts ───────────────────────────
# Bind mounts: installer ZIPs are available at build time but never written as
# image layers — eliminates ~2.3 GB of permanent COPY layers.
# chown runs at the end of the same RUN — no duplicate 3.7 GB chown layer.
RUN --mount=type=bind,source=base,target=/tmp/base \
    --mount=type=bind,source=hotfix,target=/tmp/hotfix \
    --mount=type=bind,source=plugins,target=/tmp/plugins \
    --mount=type=bind,source=plugins-hotfix,target=/tmp/plugins-hotfix \
    --mount=type=bind,source=response.silent,target=/tmp/response.silent \
    --mount=type=bind,source=custom-jars,target=/tmp/custom-jars \
    BASE_ZIP=$(ls /tmp/base/*.zip 2>/dev/null | head -1 || true) && \
    [ -n "$BASE_ZIP" ] || { echo "ERROR: No ZIP found in base/ — at least one BWCE Linux installer ZIP is required."; exit 1; } && \
    \
    echo "=== Installing base: $BASE_ZIP ===" && \
    unzip "$BASE_ZIP" -d ${TEMP_INST_DIR}/ && \
    chmod +x ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin && \
    xvfb-run ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin \
        -silent \
        -V responseFile=/tmp/response.silent \
        -V logFile=${TEMP_INST_DIR}/install.log && \
    echo "=== BASE INSTALL LOG ===" && cat ${TEMP_INST_DIR}/install.log && \
    \
    INSTALLER=${TIBCO_HOME}/tools/universal_installer/TIBCOUniversalInstaller-lnx-x86-64.bin && \
    \
    HF_ZIP=$(ls /tmp/hotfix/*.zip 2>/dev/null | head -1 || true) && \
    if [ -n "$HF_ZIP" ]; then \
      echo "=== Installing hotfix: $HF_ZIP ==="; \
      rm -rf ${TEMP_INST_DIR} && mkdir -p ${TEMP_INST_DIR}; \
      unzip "$HF_ZIP" -d ${TEMP_INST_DIR}/; \
      cp ${INSTALLER} ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin; \
      chmod +x ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin; \
      HF_NUM=$(basename "$HF_ZIP" | grep -oE 'HF-[0-9]+' | grep -oE '[0-9]+' | sed 's/^0*//'); \
      HF_SILENT=$(ls ${TEMP_INST_DIR}/TIBCOUniversalInstaller*.silent | head -1 || true); \
      sed -i "s|</properties>|<entry key=\"feature_Design Hotfix ${HF_NUM}_BW\">true</entry>\n<entry key=\"feature_Runtime Hotfix ${HF_NUM}_BW\">false</entry>\n</properties>|" \
          "${HF_SILENT}"; \
      xvfb-run ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin \
          -silent \
          -V responseFile="${HF_SILENT}" \
          -V logFile=${TEMP_INST_DIR}/hf_install.log; \
      echo "=== HF INSTALL LOG ===" && cat ${TEMP_INST_DIR}/hf_install.log; \
    else \
      echo "hotfix/ is empty — skipping HF install."; \
    fi && \
    \
    for plugin_zip in /tmp/plugins/*.zip; do \
      [ -f "$plugin_zip" ] || { echo "plugins/ is empty — skipping."; break; }; \
      echo "=== Installing plugin GA: $plugin_zip ==="; \
      rm -rf ${TEMP_INST_DIR} && mkdir -p ${TEMP_INST_DIR}; \
      unzip "$plugin_zip" -d ${TEMP_INST_DIR}/; \
      chmod +x ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin; \
      PLUGIN_SILENT=$(ls ${TEMP_INST_DIR}/TIBCOUniversalInstaller*.silent | head -1 || true); \
      sed -i "s|<entry key=\"installationRoot\">.*</entry>|<entry key=\"installationRoot\">${TIBCO_HOME}</entry>|" "${PLUGIN_SILENT}"; \
      sed -i 's|<entry key="environmentName">.*</entry>|<entry key="environmentName">TIBCO-HOME</entry>|' "${PLUGIN_SILENT}"; \
      sed -i "s|<entry key=\"configDirectoryRoot\">.*</entry>|<entry key=\"configDirectoryRoot\">${TIBCO_HOME}</entry>|" "${PLUGIN_SILENT}"; \
      xvfb-run ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin \
          -silent \
          -V responseFile="${PLUGIN_SILENT}" \
          -V logFile=${TEMP_INST_DIR}/plugin_install.log; \
      echo "=== PLUGIN GA INSTALL LOG ===" && cat ${TEMP_INST_DIR}/plugin_install.log; \
    done && \
    \
    for plugin_hf_zip in /tmp/plugins-hotfix/*.zip; do \
      [ -f "$plugin_hf_zip" ] || { echo "plugins-hotfix/ is empty — skipping."; break; }; \
      echo "=== Installing plugin HF: $plugin_hf_zip ==="; \
      rm -rf ${TEMP_INST_DIR} && mkdir -p ${TEMP_INST_DIR}; \
      unzip "$plugin_hf_zip" -d ${TEMP_INST_DIR}/; \
      cp ${INSTALLER} ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin; \
      chmod +x ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin; \
      PLUGIN_HF_SILENT=$(ls ${TEMP_INST_DIR}/TIBCOUniversalInstaller*.silent | head -1 || true); \
      sed -i "s|<entry key=\"installationRoot\">.*</entry>|<entry key=\"installationRoot\">${TIBCO_HOME}</entry>|" "${PLUGIN_HF_SILENT}"; \
      sed -i 's|<entry key="environmentName">.*</entry>|<entry key="environmentName">TIBCO-HOME</entry>|' "${PLUGIN_HF_SILENT}"; \
      sed -i "s|<entry key=\"configDirectoryRoot\">.*</entry>|<entry key=\"configDirectoryRoot\">${TIBCO_HOME}</entry>|" "${PLUGIN_HF_SILENT}"; \
      xvfb-run ${TEMP_INST_DIR}/TIBCOUniversalInstaller-lnx-x86-64.bin \
          -silent \
          -V responseFile="${PLUGIN_HF_SILENT}" \
          -V logFile=${TEMP_INST_DIR}/plugin_hf_install.log; \
      echo "=== PLUGIN HF INSTALL LOG ===" && cat ${TEMP_INST_DIR}/plugin_hf_install.log; \
    done && \
    \
    # Maven plugin install
    sed -i 's/\r$//' ${BW_HOME}/maven/install.sh && \
    cd ${BW_HOME}/maven && bash install.sh && \
    cp -r /root/.m2/repository/. /home/bwce/.m2/repository/ && \
    rm -rf /root/.m2 && \
    \
    # Custom JARs
    for jar in /tmp/custom-jars/*.jar; do \
      [ -f "$jar" ] || { echo "custom-jars/ is empty — skipping."; break; }; \
      pom="${jar%.jar}-pom.xml"; \
      if [ -f "$pom" ]; then \
        echo "=== Installing custom JAR: $jar ==="; \
        mvn install:install-file -Dfile="$jar" -DpomFile="$pom" \
            -Dmaven.repo.local=/home/bwce/.m2/repository -q; \
      else \
        echo "WARNING: $jar skipped — no matching -pom.xml found."; \
      fi; \
    done && \
    \
    # Remove install-time artifacts not needed at runtime (~1.4 GB)
    rm -rf \
        ${TIBCO_HOME}/p2repos \
        ${TIBCO_HOME}/tools/p2director \
        ${TIBCO_HOME}/tools/universal_installer \
        ${TIBCO_HOME}/thirdpartyDownload \
        ${TIBCO_HOME}/release_notes \
        ${TIBCO_HOME}/_installInfo \
        ${BW_HOME}/p2repos \
        ${BW_HOME}/backup \
        ${BW_HOME}/samples \
        ${BW_HOME}/doc && \
    \
    # chown inside same RUN — avoids a separate 3.7 GB duplicate layer
    chown -R bwce:bwce /home/bwce/.m2 ${TIBCO_HOME} && \
    rm -rf ${TEMP_INST_DIR}

# ── BWCE-11709: make $BW_HOME/bin/bwdesign display-safe ───────────────────────
# The bw6-maven-plugin bwdesignUtility goal spawns $BW_HOME/bin/bwdesign by
# absolute path (BWDesignUtilityExecutorMojo: executorHome = bwHome + "/bin"),
# so it never goes through /usr/local/bin/bwdesign. bwdesign is an SWT-GTK
# Eclipse app; with no DISPLAY it dies in gtk_init_check(). Rename the real
# launcher and put a shim in its place that supplies a virtual display only
# when one isn't already present.
RUN <<'EOF'
set -eu
cd ${BW_HOME}/bin
mv bwdesign bwdesign.bin
cp bwdesign.tra bwdesign.bin.tra
cat > bwdesign <<'WRAP'
#!/bin/bash
# Display shim — see BWCE-11709. The real launcher is bwdesign.bin.
cd "$(dirname "$0")"
if [ -n "${DISPLAY:-}" ]; then
  exec ./bwdesign.bin "$@"
fi
exec xvfb-run --auto-servernum ./bwdesign.bin "$@"
WRAP
chmod 755 bwdesign
chown bwce:bwce bwdesign bwdesign.bin bwdesign.bin.tra
EOF

# ── bwdesign wrapper ───────────────────────────────────────────────────────────
RUN printf '#!/bin/bash\ncd %s/bin\nexec dbus-run-session xvfb-run --auto-servernum ./bwdesign -nosplash "$@"\n' "${BW_HOME}" \
    > /usr/local/bin/bwdesign && \
    chmod +x /usr/local/bin/bwdesign

ENTRYPOINT []
RUN mkdir -p /workspace && chown bwce:bwce /workspace
USER bwce
WORKDIR /workspace
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8 NO_AT_BRIDGE=1
CMD ["mvn", "--version"]
