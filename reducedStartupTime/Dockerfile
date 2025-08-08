FROM debian:bookworm-slim AS builder
LABEL maintainer="Cloud Software Group, Inc."
WORKDIR /app
COPY . .
RUN chmod 755 /app/scripts/*.sh && apt-get update && apt-get --no-install-recommends -y install unzip zip && apt-get clean && rm -rf /var/lib/apt/lists/*
ENV REDUCED_STARTUP_TIME=true

# Build arguments to control optional feature inclusion
ARG EXCLUDE_GOVERNANCE=false
ARG EXCLUDE_CONFIG_MANAGEMENT=false
ARG EXCLUDE_JDBC=false

RUN  /app/scripts/customize-runtime.sh

#final stage
FROM debian:bookworm-slim
LABEL maintainer="Cloud Software Group, Inc."
RUN apt-get update && apt-get --no-install-recommends -y install unzip && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN groupadd -g 2001 bwce && useradd -m -d /home/bwce -r -u 2001 -g bwce bwce
COPY --from=builder /app/resources/addons  /resources/addons
COPY --from=builder /app/scripts /scripts
COPY --from=builder /app/bwce-runtime-unzipped /tmp
RUN chmod -R 777 /tmp /scripts /resources/addons && mkdir -p /home/default && chmod 777 /home/default
ENV HOME=/home/default
USER bwce
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]