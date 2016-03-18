FROM alpine:3.3
MAINTAINER Vijay Nalawade <vnalawad@tibco.com>
ENV GLIBC_VERSION 2.23-r1
ADD . /
RUN chmod 755 /scripts/*.sh && \
	apk add --update unzip libstdc++ bash openssh curl && \
    curl -o glibc.apk -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk" && \
    apk add --allow-untrusted glibc.apk && \
    curl -o glibc-bin.apk -L "https://github.com/andyshinn/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk" && \
    apk add --allow-untrusted glibc-bin.apk && \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc/usr/lib && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
    rm -f glibc.apk glibc-bin.apk && \
    rm -rf /var/cache/apk/*
ENTRYPOINT ["bash","/scripts/start.sh"]
