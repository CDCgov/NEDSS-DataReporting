FROM amazoncorretto:21 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY investigation-service /usr/src/investigation-service

#cd to investigation-service
WORKDIR /usr/src/

#Build person service along with any required libraries
RUN ./gradlew :investigation-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
RUN yum update -y && yum clean all
COPY --from=builder /usr/src/investigation-service/build/libs/investigation-service*.jar investigation-service.jar
# Run jar
ENTRYPOINT ["java", "-jar", "investigation-service.jar"]
CMD ["java", "-jar", "investigation-service.jar"]