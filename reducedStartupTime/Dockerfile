FROM eclipse-temurin:17-jre-alpine AS builder
LABEL maintainer="Cloud Software Group, Inc."
ADD . /
RUN chmod 755 /scripts/*.sh && \
    apk add --no-cache unzip
RUN unzip -qq /resources/bwce-runtime/bwce*.zip -d /tmp && \
    rm -rf /resources/bwce-runtime/bwce*.zip 2> /dev/null || true && \
    rm -f /tmp/tibco.home/bw*/*/system/lib/license/libFlx* 2> /dev/null || true && \
    rm -f /tmp/tibco.home/bw*/*/system/hotfix/lib/license/libFlx* 2> /dev/null || true

FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="Cloud Software Group, Inc."
RUN apk update && apk add unzip openssh net-tools jq libxslt && apk add --no-cache bash
RUN addgroup -g 2001 bwce && \
    adduser -h /home/bwce -s /bin/sh -G bwce -D -u 2001 bwce
RUN chown bwce:bwce /etc && chown -R bwce:bwce $JAVA_HOME/lib/security
COPY --chown=2001:2001 --from=builder  /tmp /tmp/
COPY --chown=2001:2001 --from=builder  /resources/addons /resources/addons/
COPY --from=builder  /scripts /scripts/
USER bwce
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]