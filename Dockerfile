FROM microsoft/nanoserver
MAINTAINER TIBCO Software Inc.
ADD . /
CMD ["powershell", "c:/scripts/start.ps1"]