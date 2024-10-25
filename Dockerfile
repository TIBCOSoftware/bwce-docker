FROM eclipse-temurin:17-jre-alpine
LABEL maintainer="Cloud Software Group, Inc."
RUN apk update && apk add unzip openssh net-tools jq libxslt && apk add --no-cache bash
RUN addgroup -S bwce -g 2001 && adduser -S bwce -G bwce -u 2001
RUN chown bwce:bwce /etc
USER bwce
ADD --chown=2001:2001 --chmod=0775  . /
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENTRYPOINT ["/scripts/start.sh"]
