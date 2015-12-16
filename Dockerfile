FROM ubuntu:14.04
MAINTAINER Vijay Nalawade <vnalawad@tibco.com>
ADD . /
RUN \
   chmod 755 /scripts/bootstrap.sh && \
   mkdir /bwapp && \
   apt-get update && \
   apt-get -y install unzip && \
   unzip -qq /resources/bwce-runtime/bwce.zip -d / && \
   chmod 755 /tibco.home/bwcf/1.*/bin/startBWAppNode.sh && \
   chmod 755 /tibco.home/bwcf/1.*/bin/bwappnode && \
   chmod 755 /tibco.home/tibcojre64/1.*/bin/java && \
   chmod 755 /tibco.home/tibcojre64/1.*/bin/javac && \
   rm -rf /resources/bwce-runtime/bwce.zip  
ENTRYPOINT ["/scripts/bootstrap.sh"]
