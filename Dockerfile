FROM microsoft/nanoserver
MAINTAINER TIBCO Software Inc.
#RUN @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
#RUN choco install -y git -params '"/GitAndUnixToolsOnPath"'
#RUN refreshenv
ADD . /
CMD ["powershell", "c:/scripts/start-240.ps1"]