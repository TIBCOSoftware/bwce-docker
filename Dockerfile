FROM debian:jessie
MAINTAINER Ronak Agarwal <roagarwa@tibco.com>
ENV JAVA_HOME="/usr/lib/jvm/java-1.8.0-openjdk-amd64"
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get -y install unzip ssh debian-keyring debian-archive-keyring
RUN echo "deb http://httpredir.debian.org/debian/ jessie-backports main" >> /etc/apt/sources.list.d/debian-jessie-backports.list
RUN echo "Package: * \
Pin: release o=Debian,a=jessie-backports \
Pin-Priority: -200" >> /etc/apt/preferences.d/debian-jessie-backports 
RUN apt-get update && apt-get -t jessie-backports -y install openjdk-8-jdk
ENTRYPOINT ["/scripts/start.sh"]