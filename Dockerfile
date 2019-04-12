FROM debian:stretch-slim
<<<<<<< HEAD
LABEL maintainer="TIBCO Software Inc."
=======
MAINTAINER TIBCO Software Inc.
>>>>>>> 5dea9992788f3fa0013c13498dd930e937f4b3a0
ADD . /
RUN chmod 755 /scripts/*.sh && apt-get update && apt-get --no-install-recommends -y install unzip ssh net-tools && apt-get clean && rm -rf /var/lib/apt/lists/*
ENTRYPOINT ["/scripts/start.sh"]
