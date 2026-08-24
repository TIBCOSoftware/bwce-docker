# custom-jars/ — extra Maven artifacts (optional)

Drop **JAR + POM pairs** here to pre-seed them into the image's local Maven repository, so BW
application POMs can resolve them without reaching an external repository at build time.

Typical use case: a company-internal shared utility library that BW processes depend on but that
is not published to Maven Central or an accessible Nexus/Artifactory.

Leave the folder empty to skip this step — the build logs `custom-jars/ is empty — skipping.`
and carries on.

## Naming rule — every JAR needs a matching POM

For each `<name>.jar` there must be a `<name>-pom.xml` alongside it:

```
custom-jars/
├── acme-common-2.4.1.jar
├── acme-common-2.4.1-pom.xml
├── acme-crypto-1.0.0.jar
└── acme-crypto-1.0.0-pom.xml
```

A JAR without its matching POM is **skipped with a warning, not an error**:

```
WARNING: acme-common-2.4.1.jar skipped — no matching -pom.xml found.
```

The build still succeeds, so check the build log if a dependency turns up missing at runtime.

## How it is used

Each pair is installed with:

```sh
mvn install:install-file -Dfile=<jar> -DpomFile=<pom> \
    -Dmaven.repo.local=/home/bwce/.m2/repository -q
```

The groupId / artifactId / version come from the POM, so make sure the POM's coordinates match
what your BW application POMs declare as dependencies.

## What belongs in the POM

A minimal POM is enough:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>com.acme</groupId>
  <artifactId>acme-common</artifactId>
  <version>2.4.1</version>
  <packaging>jar</packaging>
</project>
```

## Committing

Unlike the installer folders, small internal JARs and their POMs are often reasonable to commit
here. Use your judgement — keep large or license-restricted binaries out of git.
