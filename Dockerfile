FROM debian:wheezy
MAINTAINER Ronak Agarwal <roagarwa@tibco.com>
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get -y install unzip ssh
ENTRYPOINT ["/scripts/start.sh"]