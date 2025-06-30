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


  find bwce-runtime-unzipped -depth -type d -name 'tibcojre64' -exec rm -rv {} \;
 echo " reduced startup time is $REDUCED"

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

#create custom jre
$JAVA_HOME/bin/jlink --module-path $JAVA_HOME/jmods --add-modules java.base,java.datatransfer,java.desktop,java.instrument,java.logging,java.management,java.management.rmi,java.naming,java.net.http,java.prefs,java.rmi,java.scripting,java.se,java.security.jgss,java.security.sasl,java.sql,java.sql.rowset,java.transaction.xa,java.xml,java.xml.crypto,jdk.attach,jdk.charsets,jdk.crypto.cryptoki,jdk.crypto.ec,jdk.dynalink,jdk.hotspot.agent,jdk.httpserver,jdk.internal.ed,jdk.internal.jvmstat,jdk.internal.le,jdk.internal.opt,jdk.jcmd,jdk.jdi,jdk.jdwp.agent,jdk.jfr,jdk.jsobject,jdk.jstatd,jdk.localedata,jdk.management,jdk.management.agent,jdk.management.jfr,jdk.naming.dns,jdk.naming.rmi,jdk.net,jdk.sctp,jdk.security.auth,jdk.security.jgss,jdk.unsupported,jdk.unsupported.desktop,jdk.xml.dom,jdk.zipfs --output /opt/custom-java --strip-debug --compress=1 --no-man-pages --no-header-files