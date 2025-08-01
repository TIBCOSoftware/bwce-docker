#!/bin/sh
set -e
REDUCED="${REDUCED_STARTUP_TIME:-false}"

for f in /app/resources/bwce-runtime/bwce-runtime*.zip; do
  unzip "$f" -d bwce-runtime-unzipped

  # Remove governance features if exclude is true
  if [ "$EXCLUDE_GOVERNANCE" = "true" ]; then
    find bwce-runtime-unzipped -depth -type d -name 'com.tibco.governance*' -exec rm -rv {} \;
    find bwce-runtime-unzipped -type f -name 'com.tibco.governance*' -exec rm -v {} +
    find bwce-runtime-unzipped -depth -type d -name 'org.hsqldb*' -exec rm -v {} \;
  fi

  # Remove config management features if exclude is true
  if [ "$EXCLUDE_CONFIG_MANAGEMENT" = "true" ]; then
    find bwce-runtime-unzipped -type f -name 'com.tibco.configuration.management.services*' -exec rm -v {} +
  fi

  # Remove all JDBC drivers if exclude is true
  if [ "$EXCLUDE_JDBC" = "true" ]; then
    find bwce-runtime-unzipped -depth -type d -name 'com.tibco.bw.tpcl.jdbc.datasourcefactory.mariadb*' -exec rm -rv {} \;
    find bwce-runtime-unzipped -depth -type d -name 'com.tibco.bw.tpcl.jdbc.datasourcefactory.postgresql*' -exec rm -rv {} \;
    find bwce-runtime-unzipped -depth -type d -name 'com.tibco.bw.tpcl.jdbc.datasourcefactory.sqlserver*' -exec rm -rv {} \;
    find bwce-runtime-unzipped -depth -type d -name 'com.tibco.bw.tpcl.jdbc.datasourcefactory.oracle*' -exec rm -rv {} \;
  fi

  # Remove Alpine-specific FlexNet libraries
  rm -rf bwce-runtime-unzipped/tibco.home/bw*/*/system/lib/license/alpine 2> /dev/null || true
  rm -rf bwce-runtime-unzipped/tibco.home/bw*/*/system/hotfix/lib/license/alpine 2> /dev/null || true

  # Re-zip the modified runtime if reduced startup time is false
  if [ "$REDUCED" != "true" ]; then
    echo "reduced startup time is false"
    cd bwce-runtime-unzipped
    zip -r /app/tmp.zip .
    cd ..
    mv /app/tmp.zip "$f"
    rm -rf bwce-runtime-unzipped
  fi
done