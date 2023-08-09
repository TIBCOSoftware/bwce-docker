#Use this dockerfile to unzip the bwce-runtime zip while creating the base image.
FROM eclipse-temurin:11-alpine
LABEL maintainer="TIBCO Software Inc."
ADD . /
RUN chmod 755 /scripts/*.sh && apk update && apk add unzip openssh net-tools && apk add --no-cache bash
ENTRYPOINT ["/scripts/start.sh"]
