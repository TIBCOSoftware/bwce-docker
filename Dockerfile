FROM eclipse-temurin:11.0.15_10-jre-alpine
LABEL maintainer="TIBCO Software Inc."
ADD . /
RUN chmod 755 /scripts/*.sh && apk update && apk add unzip openssh net-tools
RUN apk add --no-cache bash
ENTRYPOINT ["/scripts/start.sh"]
