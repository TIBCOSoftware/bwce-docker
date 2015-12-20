FROM ubuntu:14.04
MAINTAINER Vijay Nalawade <vnalawad@tibco.com>
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get -y install unzip
ENTRYPOINT ["/scripts/bootstrap.sh"]
