#Use this dockerfile to unzip the bwce-runtime zip while creating the base image.
FROM debian:buster-slim
LABEL maintainer="TIBCO Software Inc."
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get --no-install-recommends -y install unzip ssh net-tools && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN groupadd -g 2001 bwce \
&& useradd -r -u 2001 -g bwce bwce
RUN unzip -qq /resources/bwce-runtime/bwce*.zip -d /tmp && rm -rf /resources/bwce-runtime/bwce*.zip 2> /dev/null
RUN chown -R bwce:bwce /tmp
USER bwce
ENTRYPOINT ["/scripts/start.sh"]
