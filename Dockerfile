FROM frolvlad/alpine-glibc:latest
MAINTAINER Vijay Nalawade <vnalawad@tibco.com>
ADD . /
RUN chmod 755 /scripts/*.sh && \
	apk add --update wget ca-certificates unzip libstdc++ bash openssh curl && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    apk del wget ca-certificates
ENTRYPOINT ["bash","/scripts/start.sh"]
