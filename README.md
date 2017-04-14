# Scripts for customizing Docker images for TIBCO BusinessWorks™ Container Edition 
The TIBCO BusinessWorks™ Container Edition (BWCE) Docker image is a highly extensible Docker base image for running TIBCO BusinessWorks Container Edition applications. This image can be customized for supported third-party drivers, OSGi™ bundles, integration with application configuration management systems, application certificate management etc.

TIBCO BusinessWorks Container Edition allows customers to build microservices with an API-first approach and deploy them to cloud-native platforms such as [Cloud Foundry™](http://pivotal.io/platform) and [Kubernetes](http://kubernetes.io/). By elegantly right-sizing TIBCO ActiveMatrix BusinessWorks™, it brings visual application development and integration capabilities to any enterprise platform as a service.

To know more about TIBCO BusinessWorks Container Edition, visit [Documentation](https://docs.tibco.com/products/tibco-businessworks-container-edition-2-0-0)

These Docker scripts are subject to the license shared as part of the repository. Review the license before using or downloading these scripts.

## Prerequisite
  * Access to [TIBCO® eDelivery](https://edelivery.tibco.com)
  * [Docker](https://docs.docker.com/engine/installation/)
    
## Download TIBCO BusinessWorks Container Edition
Download the appropriate TIBCO BusinessWorks Container Edition 2.0.0 artifacts from [TIBCO® eDelivery](https://edelivery.tibco.com/storefront/eval/tibco-businessworks-container-edition/prod11654.html). It contains TIBCO BusinessWorks Container Edition runtime (bwce_cf.zip).
     
## Create TIBCO BusinessWorks Container Edition Base Docker Image
   1. Clone this repository onto your local machine.
   2. Locate the bwce_cf.zip file from the downloaded artifacts and run [createDockerImage.sh](createDockerImage.sh). This will create the TIBCO BusinessWorks Container Edition base Docker image.

## Extend TIBCO BusinessWorks Container Edition Base Docker Image
You can customize the base Docker image for supported third-party drivers e.g. Oracle JDBC drivers, OSGi™ bundles or to add runtime of supported Plug-ins in TIBCO BusinessWorks Container Edition runtime. It can also be customized for application certificate management as well as to integrate with application configuration management services.
* **Provision supported JDBC drivers**:
     * Run **bwinstall[.exe] help** from `<BWCE_HOME>/bin` and follow instructions to add the driver to your TIBCO BusinessWorks Container Edition installation.
     * Copy the appropriate driver OSGi bundle from `<BWCE_HOME>/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to the `<Your-local-Docker-repo>/resources/addons/jars` folder. 
* **Provision [OSGi](https://www.osgi.org) bundle jar(s)**: Copy OSGi bundle jar(s) into `<Your-local-docker-repo>/resources/addons/jars`
* **Application Configuration Management**: TIBCO BusinessWorks Container Edition supports [Consul](https://www.consul.io/) configuration mechanism out of the box. Refer https://docs.tibco.com/pub/bwce/2.0.0/doc/html/GUID-3AAEE4AD-8701-4F4E-AD7B-2416A9DDA260.html for further details. To add support for other systems, update `<Your-local-Docker-repo>/java-code/ProfileTokenResolver.java`. This class has a dependecy on Jackson(2.6.x) JSON library. You can pull these dependencies from the installation `<BWCE_HOME>/system/shared/com.tibco.bw.tpcl.com.fasterxml.jackson` or download it from the web.
* **Certificate Management**: There are use cases where you need to use certificates into your application to connect to different systems. For example, a certificate to connect to TIBCO Enterprise Message Service™. Bundling certificates with your application is not a good idea as you would need to rebuild your application when the certificates expire. To avoid that, you can copy your certificates into the `<Your-local-Docker-repo>/resources/addons/certs` folder. Once the certificates expire, you can simply copy the new certificates into the base Docker image without rebuilding your application. Just build your application with the base Docker image. To access the certificates from your application, use the environment variable [BW_KEYSTORE_PATH]. For example, #BW_KEYSTORE_PATH#/mycert.jks.
*  **Provision TIBCO BusinessWorks™ Container Edition Plug-in Runtime**: 
   * TIBCO Certified Plug-Ins: The TIBCO BusinessWorks™ Container Edition has certified a few plug-ins. Contact `TIBCO Support` for the list of all supported plug-ins. To add a plug-in runtime into your base Docker image:
     * Download the appropriate plug-in packaging for example, TIBCO ActiveMatrix BusinessWorks(TM) Plug-in for WebSphere MQ from https://edelivery.tibco.com
     * Locate the plug-in runtime zip file e.g. `<ProductID>_ePaas.zip` or `TIB_<ProductID>_<ProductionVersion>_<BuildNumber>_bwce-runtime.zip` file from the downloaded artifacts and copy into `<Your-local-buildpack-repo>/resources/addons/plugins`
  * Plug-ins created using [TIBCO ActiveMatrix BusinessWorks™ Plug-in Development Kit](https://docs.tibco.com/products/tibco-activematrix-businessworks-plug-in-development-kit-6-1-1), the plug-in runtime must be added to the base Docker image. To add the plug-in runtime into your base docker image:
    * [Install Plug-In](https://docs.tibco.com/pub/bwpdk/6.1.1/doc/html/GUID-0FB70A84-DBF6-4EE6-A6C8-28AC5E4FF1FF.html) if not already installed.
    * Navigate to the `<TIBCO-HOME>/bwce/palettes/<plugin-name>/<plugin-version>` directory and  zip the `lib` and `runtime` folders into `<plugin-name>.zip` file. Copy `<plugin-name>.zip` to `<Your-local-Docker-repo>/resources/addons/plugins` folder.
  * Copy any OSGi bundles required by the plug-in for example, driver bundle into `<Your-local-Docker-repo>/resources/addons/jars`

Run [createDockerImage.sh](createBuildpack.sh) to create the TIBCO BusinessWorks™ Container Edition base Docker image.
     
## Test TIBCO BusinessWorks Container Edition Base Docker Image
  * Navigate to the [examples/HTTP](/examples/HTTP) directory and update the base Docker image in [Dockerfile](/examples/HTTP/Dockerfile) to your TIBCO BusinessWorks™ Container Edition base Docker image.
  * From the [examples/HTTP](/examples/HTTP) directory, build the TIBCO BusinessWorks™ Container Edition application: `docker build -t bwce-http-app .`
  * Run the TIBCO BusinessWorks™ Container Edition application: `docker run -P -e MESSAGE='Welcome to BWCE 2.0 !!!' bwce-http-app`
  * Find the port number mapped to 8080 using `docker ps` and send a request to `http://<DOCKER-HOST-IP>:<HOST-PORT>`. It should return 'Welcome to BWCE 2.0 !!!' message. In case of failure, inspect the logs.

## License
These buildpack scripts are released under a [3-clause BSD-type](License.md) license.

TIBCO, ActiveMatrix, ActiveMatrix BusinessWorks, TIBCO BusinessWorks, and TIBCO Enterprise Message Service are trademarks or registered trademarks of TIBCO Software Inc. in the United States and/or other countries.

Docker is a trademark or registered trademark of Docker, Inc. in the United States and/or other countries. 

OSGi is a trademark or a registered trademark of the OSGi Alliance in the United States, other countries, or both.
     
