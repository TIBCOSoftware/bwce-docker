FROM debian:bookworm-slim
LABEL maintainer="Cloud Software Group, Inc."
RUN apt-get update && apt-get --no-install-recommends -y install unzip ssh net-tools jq && apt-get -y install xsltproc && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN groupadd -g 2001 bwce \
&& useradd -m -d /home/bwce -r -u 2001 -g bwce bwce
COPY license /opt/tibco/license/
RUN chown bwce:bwce /etc
USER bwce
ADD --chown=2001:2001 --chmod=0775  . /
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]
