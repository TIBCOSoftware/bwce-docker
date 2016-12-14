FROM debian:jessie
MAINTAINER TIBCO Software Inc.
ADD . /
RUN chmod 755 /scripts/*.sh && chmod -R 777 /resources && apt-get update && apt-get -y install unzip ssh
ENTRYPOINT ["/scripts/start.sh"]
