FROM debian:bookworm-slim AS builder
LABEL maintainer="Cloud Software Group, Inc."
ADD . /
RUN chmod 755 /scripts/*.sh &&  apt-get update && apt-get --no-install-recommends -y install unzip  && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN unzip -qq /resources/bwce-runtime/bwce*.zip -d /tmp && rm -rf /resources/bwce-runtime/bwce*.zip 2> /dev/null

FROM debian:bookworm-slim
LABEL maintainer="Cloud Software Group, Inc."
RUN apt-get update && apt-get --no-install-recommends -y install unzip ssh net-tools  && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN groupadd -g 2001 bwce \
&& useradd -r -u 2001 -g bwce bwce
USER bwce
COPY --chown=2001:2001 --from=builder  /tmp /tmp/
COPY --chown=2001:2001 --from=builder  /resources/addons /resources/addons/
COPY --from=builder  /scripts /scripts/
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]
