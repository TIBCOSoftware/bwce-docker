FROM debian:jessie-slim
MAINTAINER TIBCO Software Inc.
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get --no-install-recommends -y install unzip ssh net-tools && apt-get clean && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/scripts/start.sh"]
