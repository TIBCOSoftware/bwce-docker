#Command to Execute this script - 
#sh helper_script.sh ~/Desktop/nitish-files-backup/2.4.0/bwce-runtime-2.4.0.zip rest


#Docker clean-up commands
#=========================

#docker system prune
docker stop $(docker ps -q -a)

#Build Base Image
#=========================

if [[ $# -lt 1 ]]; then
    echo "Usage: ./helper_script.sh <path/to/bwce-runtime-2.4.0.zip>"
    printf "\t %s \t\t %s \n\t\t\t\t %s \n" "Location of runtime zip (bwce-runtime-<version>.zip)"
    exit 1
fi
zipLocation=$1

cd c:/bwce/bwce-docker
#./createDockerImage.sh ~/Desktop/nitish-files-backup/2.4.0/bwce-runtime-2.4.0.zip
./createDockerImage.sh $zipLocation


if [ -z "$2"  ]; then
	cd examples/HTTP
	docker build -t bwce-http-app-nano .
	docker run -it -P -e BW_LOGLEVEL=ERROR -e MESSAGE='Welcome to BWCE 2.0 !!!' bwce-http-app-nano
fi

sampleApplication=$2

#HTTP Sample Commands
#=========================
if [ "$sampleApplication" = "http" ]; then
	cd examples/HTTP
	docker build -t bwce-http-app-nano .
	docker run -it -P -e BW_LOGLEVEL=ERROR -e MESSAGE='Welcome to BWCE 2.0 !!!' bwce-http-app-nano
fi

#REST Sample Commands
#=========================
if [ "$sampleApplication" = "rest" ]; then
	cd examples/REST
	docker build -t bwce-rest-app-nano .
	docker run -it -P -e BW_LOGLEVEL=DEBUG bwce-rest-app-nano
fi

#JMS Sample Commands
#=========================
if [ "$sampleApplication" = "jms" ]; then
	cd examples/JMS
	docker build -t bwce-jms-app-nano .
	docker run -ti -e EMS_URL="tcp://13.56.67.132:7222" -e EMS_QUEUE="jmsbasic.queue" -e REPLY_QUEUE="reply.queue" -e BW_PROFILE="docker" bwce-jms-app-nano
fi

#Hystrix Sample Commands
#=========================
if [ "$sampleApplication" = "hystrix" ]; then
	cd examples/Hystrix
	docker build -t bwce-hystrix-app-nano .
	docker run -i -p 8081:8081 -p 8090:8090 -e BW_PROFILE="docker" -e COMMAND_NAME=WikiNews-Service -e BW_LOGLEVEL=info bwce-hystrix-app-nano
fi

#JMS with Consul Sample Commands
#=========================
if [ "$sampleApplication" = "consul-jms" ]; then
	cd examples/consul/client
	docker build -t bwce-consul-sd-client-nano .
	cd c:/bwce/bwce-docker/examples/consul/server
	docker build -t bwce-consul-sd-server-nano .

	docker run -d -e CONSUL_SERVER_URL=http://13.57.245.44:8500/ -p 18087:8080 -e SERVICE_NAME=BWCE-HELLOWORLD-SERVICE bwce-consul-sd-server-nano:latest
	docker run -d -e CONSUL_SERVER_URL=http://13.57.245.44:8500/ -p 18086:8080 -e SERVICE_NAME=BWCE-HELLOWORLD-SERVICE bwce-consul-sd-client-nano:latest
fi


#RestBookstore(JDBC) Sample Commands
#=========================
if [ "$sampleApplication" = "jdbc" ]; then
	cd examples/JDBC
	docker build -t bwce-jdbc-app-nano .
	#docker run -p 8080:8080 -e BW_LOGLEVEL=DEBUG bwce-jdbc-app-nano [use this if vales are hardcoded in the applicatiopn/module properties]
	docker run -p 8080:8080 -e BW_LOGLEVEL=DEBUG -e DB_URL="xxx-xxx-xxx" -e DB_USERNAME="dummy" -e DB_PASSWORD="nitish" bwce-jdbc-app-nano
fi

