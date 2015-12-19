##Caution
Fon internal use only. **Must not be shared outside BW engineering**.

##Prerequiste
Install [Docker Engine](https://docs.docker.com/engine/installation) , [Docker Machine](https://docs.docker.com/machine/install-machine).

##Create BWCE base docker Image
1. Clone this repo
2. Download modified **bwce.zip** from https://drive.google.com/open?id=0B-tPKrxN5XKzRzlFTjJQcXYxQWM and copy it to _/resources/bwce-runtime_ folder. You need access permission to download it. Contact vnalawad@tibco.com for access permission.
2. Build docker image from repo folder e.g. 
 	_docker build  -t **tibco/bwce:v1.1.0** ._
3. Run BWCE application
	* In Local Environment: In local enviornment, run BWCE application by mapping volume containing ear file to / volume in the container
		e.g.  _docker run --name BWRESTAPP -d **-v /Users/vnalawad/docker-apps/testrest_1.0.0.ear:/testrest_1.0.0.ear** -p 18080:8080 -p 17777:7777 **tibco/bwce:v1.1.0**_. [See docker for more info](https://docs.docker.com/engine/userguide/dockervolumes)
	* Build Application docker image: To run application on docker based PAAS platforms, create application docker image. 
		* Build Image: Create application Dockerfile and ear [[Example](examples/HTTP)] and build image. _Ensure that application docker image is created using BWCE base image [[See](examples/HTTP/Dockerfile)]._ e.g. **docker build -t docker.http.application:1.0 .**. 
		* Run application using application image e.g.  _docker run -e MESSAGE='Welcome to BWCE' --log-driver=syslog --log-opt syslog-address=udp://logs3.papertrailapp.com:39293 -d -P docker.http.application:1.0_

##Supported Features
* **Application configuration through Environment Variables**: BWCE application can be configured with env variables. Use #ENV-VAR-NAME# token in the application profile. Only supported for default application profile (default.substvar). e.g. _docker run --name BWHTTPAPP **-e MESSAGE='BWCE Rocks on Docker'** -d -v /Users/vnalawad/docker-apps/docker.http.application_1.0.0.ear:/docker.http.application_1.0.0.ear -p 18081:8080 tibco/bwce:v1.1.0_
* **Logging using Papertrail**: Run your BWCE application with  _--log-driver=syslog --log-opt syslog-address=udp://{your-papertrail-log-destination}_  e.g. docker run --name BWRESTAPP  **--log-driver=syslog --log-opt syslog-address=udp://logs3.papertrailapp.com:11111** -d -v /Users/vnalawad/docker-apps/testrest_1.0.0.ear:/testrest_1.0.0.ear -p 18080:8080 -p 17777:7777 tibco/bwce:v1.1.0. [More Options](http://help.papertrailapp.com/kb/configuration/configuring-centralized-logging-from-docker)
