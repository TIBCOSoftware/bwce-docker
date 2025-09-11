FROM eclipse-temurin:17-jre-alpine AS builder
RUN apk update && apk add unzip zip
ADD . /app
RUN unzip -q /app/resources/bwce-runtime/bwce*.zip -d /app/bwce-runtime-unzipped && \
    rm -f /app/bwce-runtime-unzipped/tibco.home/bw*/*/system/lib/license/libFlx* 2> /dev/null || true && \
    rm -f /app/bwce-runtime-unzipped/tibco.home/bw*/*/system/hotfix/lib/license/libFlx* 2> /dev/null || true
RUN cd /app/bwce-runtime-unzipped && zip -r /app/bwce-runtime.zip . && mv /app/bwce-runtime.zip /app/resources/bwce-runtime/bwce*.zip

FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="Cloud Software Group, Inc."
RUN apk update && apk add unzip openssh net-tools jq libxslt && apk add --no-cache bash
RUN addgroup -S bwce -g 2001 && adduser -S bwce -G bwce -u 2001
RUN chown bwce:bwce /etc && \
    chown -R bwce:bwce $JAVA_HOME/lib/security
COPY --chown=2001:2001 --chmod=0775 --from=builder /app/resources  /resources
COPY --chown=2001:2001 --chmod=0775 --from=builder /app/scripts /scripts
USER bwce
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]