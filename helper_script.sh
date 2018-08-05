#Docker clean-up commands
#=========================

#docker system prune
docker stop $(docker ps -q -a)

#Build Base Image
#=========================

cd c:/bwce/bwce-docker
#./createDockerImage.sh ~/Desktop/nitish-files-backup/windows-runtime-zip-with-jre-replaced/wrapper-zip/bin-folder-replaced-in-wrapper/bwce-runtime-2.3.2.zip 
./createDockerImage-240.sh ~/Desktop/nitish-files-backup/2.4.0/bwce-runtime-2.4.0.zip



#HTTP Sample Commands
#=========================

cd examples/HTTP
docker build -t bwce-http-app-nano .
docker run -it -P -e BW_LOGLEVEL=INFO -e MESSAGE='Welcome to BWCE 2.0 !!!' bwce-http-app-nano


#REST Sample Commands
#=========================

#cd examples/REST
#docker build -t bwce-rest-app-nano .
#docker run -it -P -e MESSAGE='Welcome to BWCE 2.0 !!!' bwce-rest-app-nano
#docker run -e BW_LOGLEVEL=ERROR MESSAGE='HELL YES' bwce-http-app


#JMS Sample Commands
#=========================

#cd examples/JMS
#docker build -t bwce-jms-app-nano .
#docker run -ti -e EMS_URL="tcp://13.56.67.132:7222" -e EMS_QUEUE="jmsbasic.queue" -e REPLY_QUEUE="reply.queue" -e BW_PROFILE="docker" bwce-jms-app-nano


#Hystrix Sample Commands
#=========================

#cd examples/Hystrix
#docker build -t bwce-hystrix-app-nano .
#docker run -i -p 8081:8081 -p 8090:8090 -e BW_PROFILE="docker" -e COMMAND_NAME=WikiNews-Service -e BW_LOGLEVEL=info bwce-hystrix-app-nano


#JMS with COnsul Sample Commands
#=========================

#cd examples/consul/client
#docker build -t bwce-consul-sd-client-nano .
#cd c:/bwce/bwce-docker/examples/consul/server
#docker build -t bwce-consul-sd-server-nano .

#docker run -d -e CONSUL_SERVER_URL=http://13.57.245.44:8500/ -p 18087:8080 -e SERVICE_NAME=BWCE-HELLOWORLD-SERVICE bwce-consul-sd-server-nano:latest
#docker run -d -e CONSUL_SERVER_URL=http://13.57.245.44:8500/ -p 18086:8080 -e SERVICE_NAME=BWCE-HELLOWORLD-SERVICE bwce-consul-sd-client-nano:latest



#RestBookstore(JDBC) Sample Commands
#=========================

#cd examples/JDBC
#docker build -t bwce-jdbc-app-nano .
#docker run -p 8080:8080 -e BW_LOGLEVEL=DEBUG bwce-jdbc-app-nano [use this if vales are hardcoded in the applicatiopn/module properties]
#docker run -p 8080:8080 -e BW_LOGLEVEL=DEBUG -e DB_URL="jdbc:postgresql://nitish-db-instance.cqhaluv3epe3.us-east-1.rds.amazonaws.com:5432/postgres" -e DB_USERNAME="nitish" -e DB_PASSWORD="nitish123" bwce-jdbc-app-nano
