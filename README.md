##Prerequiste
Install [Docker Engine](https://docs.docker.com/engine/installation) , [Docker Machine](https://docs.docker.com/machine/install-machine) .

##Create BWCE base docker Image
1. Clone this repo
2. Build docker image from repo folder e.g. 
 	_docker build  -t **tibco/bwce:v1.1.0** ._
3. Run BWCE application
	* Local Environment: In local enviornment, run BWCE application by mapping volume containing ear file to /bwapp volume in the container
		e.g.  _docker run --name BWRESTAPP -d **-v /Users/vnalawad/docker-apps/testrest_1.0.0.ear:/bwapp/testrest_1.0.0.ear** -p 18080:8080 -p 17777:7777 **tibco/bwce:v1.1.0.2**_. [See docker for more info](https://docs.docker.com/engine/userguide/dockervolumes)
	* On PAAS platforms: TODO

##Supported Features
* Environment variable: BWCE application can be configured with env variable. Use #ENV-VAR-NAME# token in the application profile. Only supported for default application profile (default.substvar). e.g. _docker run --name BWHTTPAPP **-e MESSAGE='BWCE Rocks on Docker'** -d -v /Users/vnalawad/docker-apps/docker.http.application_1.0.0.ear:/bwapp/docker.http.application_1.0.0.ear -p 18081:8080 tibco\bwce:v1.1.0.2_
