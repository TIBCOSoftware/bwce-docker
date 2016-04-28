# Docker Scripts for TIBCO BusinessWorks™ Container Edition 
The TIBCO BusinessWorks™ Container Edition (BWCE) Docker image is a highly extensible docker base image for running TIBCO BusinessWorks™ Container Edition applications. This image can be customized for supported third-party drivers, OSGI bundles, integration with application configuration management systems, application certificate management etc.

TIBCO BusinessWorks(TM) Container Edition allows customers to leverage the power and functionality of TIBCO ActiveMatrix BusinessWorks(TM) in order to build cloud-native applications with an API-first approach and to deploy it to container-based PaaS platforms such as [Cloud Foundry(TM)](http://pivotal.io/platform), [Kubernetes](http://kubernetes.io/) etc.

To find more about TIBCO BusinessWorks™ Container Edition, refer https://docs.tibco.com/products/tibco-businessworks-container-edition-2-0-0

These docker scripts are subject to the license shared as part of the repository. Review the license before using or downloading these scripts.

##Prerequisite
  * Need access to https://edelivery.tibco.com.
  * Install [Docker](https://docs.docker.com/engine/installation/).
    
##Download TIBCO BusinessWorks™ Container Edition
Download appropriate TIBCO BusinessWorks™ Container Edition 2.0.0 artifacts from [https://edelivery.tibco.com](https://edelivery.tibco.com/storefront/eval/tibco-businessworks-container-edition/prod11654.html). It contains TIBCO BusinessWorks™ Container Edition runtime (bwce_cf.zip).
     
##Create BWCE Base Docker Image
   1. Clone this repository onto your local machine.
   2. Locate bwce_cf.zip file from the downloaded artifacts and run [createDockerImage.sh](createDockerImage.sh). This will create BWCE base docker image.

##Extend BWCE Base Docker Image
You can customize base docker iamge to add supported third-party drivers e.g. Oracle JDBC driver, OSGified bundles or runtime of certified Plug-ins in TIBCO BusinessWorks™ Container Edition runtime. It can also be customized for application certificate management as well as to integrate with application configuration management services.
* **Provision suppprted JDBC drivers**:
     * Follow steps described in "Using Third Party JDBC Drivers" on https://docs.tibco.com/pub/bwce/2.0.0/doc/html/GUID-881316C3-28F9-4BCF-A512-38B731BE63D1.html.
     * Copy the appropriate driver bundle from `<TIBCO_HOME>/bwce/2.x/config/drivers/shells/<driverspecific runtime>/runtime/plugins/` to  `<Your-local-docker-repo>/resources/addons/jars` folder. 
* **Provision [OSGi](https://www.osgi.org) bundle jar(s)**: Copy OSGified bundle jar(s) into `<Your-local-docker-repo>/resources/addons/jars`
* **Application Configuration Management**: TIBCO BusinessWorks™ Container Edition supports [Consul](https://www.consul.io/) configuration mechanism out of the box. Refer https://docs.tibco.com/pub/bwce/2.0.0/doc/html/GUID-3AAEE4AD-8701-4F4E-AD7B-2416A9DDA260.html for further details. To add support for other systems, update `<Your-local-docker-repo>/java-code/ProfileTokenResolver.java`. This class has a dependecy on Jackson(2.6.x) JSON library. You can pull this dependencies from the installation `<TIBCO_HOME>/bwce/2.x/system/shared/com.tibco.bw.tpcl.com.fasterxml.jackson` or download it from the web.
* **Certificate Management**: There are use cases where you need to use certificates into your application to connect to different systems. For example, a certificate to connect to TIBCO Enterprise Message Service. Bundling certificates with your application is not a good idea as you would need to rebuild your application when the certificates expire. To avoid that, you can copy your certificates into the `<Your-local-docker-repo>/resources/addons/certs` folder. Once the certificates expire, you can copy the new certificates into the buildpack without rebuilding your application. Just push your application with the new buildpack. To access the certificates folder from your application, use the environment variable [BW_KEYSTORE_PATH]. For example, #BW_KEYSTORE_PATH#/mycert.jks in your application property.
*  **Provision TIBCO BusinessWorks™ Container Edition Plug-in Runtime**: For Plug-ins created using [TIBCO ActiveMatrix BusinessWorks™ Plug-in Development Kit](https://docs.tibco.com/products/tibco-activematrix-businessworks-plug-in-development-kit-6-1-1), their runtime must be added to the base docker image. To add Plug-in runtime into your base docker image:
  * [Install Plug-In](https://docs.tibco.com/pub/bwpdk/6.1.1/doc/html/GUID-0FB70A84-DBF6-4EE6-A6C8-28AC5E4FF1FF.html) if not already installed
  * Goto `<TIBCO-HOME>/bwce/palettes/<plugin-name>/<plugin-version>` directory and  zip `lib` and `runtime` folders into <plugin-name>.zip file. Copy <plugin-name>.zip into `<Your-local-docker-repo>/resources/addons/plugins`
  * Copy any OSGi bundles required by Plug-in e.g. driver bundles into `<Your-local-buildpack-repo>/resources/addons/jars`

Run [createDockerImage.sh](createBuildpack.sh) to create BWCE base docker image.
     
##Test BWCE Base Docker Image
  * Goto [example/http](/example/http) directory and update base docker image in Dockerfile to your BWCE base docker image
  * Build application docker image: `docker build -t BWCE-HTTP-APP .`
  * Run application docker image: `docker run -P -e MESSAGE='Welcome to BWCE 2.0 !!!' BWCE-HTTP-APP`
  * Find Host port mapped to 8080 using `docker ps` and send request to `http://<DOCKER-HOST-IP>:<HOST-PORT>`. It should return 'Welcome to BWCE 2.0 !!!' message. In case of failure, inspect logs.

##License
These buildpack scripts are released under [3-clause BSD](License.md) license.
     
