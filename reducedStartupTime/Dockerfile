FROM eclipse-temurin:17.0.13_11-jdk-alpine AS builder
LABEL maintainer="Cloud Software Group, Inc."
WORKDIR /app
COPY . .
RUN chmod 755 /app/scripts/*.sh && apk update && apk add --no-cache unzip zip bash jq
ENV REDUCED_STARTUP_TIME=true
# Build arguments to control optional feature inclusion
ARG EXCLUDE_GOVERNANCE=faslse
ARG EXCLUDE_CONFIG_MANAGEMENT=false
ARG EXCLUDE_JDBC=false

RUN  /app/scripts/customize-runtime.sh

#final stage
FROM alpine:3.19 AS final
LABEL maintainer="Cloud Software Group, Inc."

RUN rm -rf /opt/java && mkdir -p /opt/java
COPY --from=builder /app/resources  /resources
COPY --from=builder /app/scripts /scripts
COPY --chown=2001:2001 --from=builder /opt/custom-java /opt/java
COPY --chown=2001:2001  --from=builder /app/bwce-runtime-unzipped /tmp

RUN chmod 755 /scripts/*.sh
ENV JAVA_HOME=/opt/java
ENV PATH="$JAVA_HOME/bin:$PATH"
RUN apk update && apk add --no-cache unzip  && apk add --no-cache bash && apk add --no-cache binutils
RUN addgroup -S bwce -g 2001 && adduser -S bwce -G bwce -u 2001
USER bwce
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]


