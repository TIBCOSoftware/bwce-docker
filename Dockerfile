FROM alpine:3.4
MAINTAINER TIBCO Software Inc.
ENV JAVA_HOME="/usr/lib/jvm/default-jvm"
ADD . /
RUN chmod 755 /scripts/*.sh && \
#apk update && \
apk --no-cache --update add unzip openssh openjdk8 bash libstdc++ && \
rm -rf /var/cache/apk/* 
ENTRYPOINT ["/scripts/start.sh"]