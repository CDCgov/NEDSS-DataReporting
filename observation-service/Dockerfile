FROM amazoncorretto:25 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY observation-service /usr/src/observation-service

#cd to observation-service
WORKDIR /usr/src/

#Build person service along with any required libraries
RUN ./gradlew :observation-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:25
RUN yum update -y && yum clean all
COPY --from=builder /usr/src/observation-service/build/libs/observation-service*.jar observation-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "observation-service.jar"]
CMD ["java", "-jar", "observation-service.jar"]