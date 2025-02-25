# Scripts for customizing Docker images for TIBCO BusinessWorks™ Container Edition on TIBCO Platform
The TIBCO BusinessWorks™ Container Edition (BWCE) Docker image is a highly extensible Docker base image for running TIBCO BusinessWorks Container Edition applications. These sample scripts for debian base image can be customized as per customer need to create their own custom base image and same can be registered on their dataplane using TIBCO BusinessWorks™ Container Edition Capability public APIs on the dataplane.

## Prerequisite
  * Access to [TIBCO® eDelivery](https://edelivery.tibco.com)
  * [Docker](https://docs.docker.com/engine/installation/)
    
## Download TIBCO BusinessWorks Container Edition
Download the appropriate TIBCO BusinessWorks Container Edition artifacts from [TIBCO® eDelivery](https://edelivery.tibco.com/storefront/eval/tibco-businessworks-container-edition/prod11654.html). It contains TIBCO BusinessWorks Container Edition runtime (`bwce-runtime-<version>.zip`).
     
## Create TIBCO BusinessWorks Container Edition Base Docker Image
   1. Clone this repository onto your local machine.
   2. Locate the `bwce-runtime-<version>.zip` (e.g. bwce-runtime-2.10.0.zip) file from the downloaded artifacts and copy it under ./resources/bwce-runtime folder.
   3. If you are using windows, please ensure CRLF chars are replaced with LF in all script files before building the docker image, Otherwise you may see error `exec /scripts/start.sh: no such file or directory`
   4. Run `docker build -t tp-bwce-base:<tag> .` command and push image to your custom container registry configured for your dataplane.
   5. Invoke `/v1/dp/bwceversions/{version}/custombaseimage` TIBCO BusinessWorks™ Container Edition Capability public API to register the custom base image.

## License
These buildpack scripts are released under a [3-clause BSD-type](License.md) license.

TIBCO, ActiveMatrix, ActiveMatrix BusinessWorks, TIBCO BusinessWorks, and TIBCO Enterprise Message Service are trademarks or registered trademarks of TIBCO Software Inc. in the United States and/or other countries.

Docker is a trademark or registered trademark of Docker, Inc. in the United States and/or other countries. 

OSGi is a trademark or a registered trademark of the OSGi Alliance in the United States, other countries, or both.
     
