FROM amazoncorretto:21 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY status-service /usr/src/status-service

#cd to root directory
WORKDIR /usr/src/

#Build status service along with any required libraries
RUN ./gradlew :status-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
COPY --from=builder /usr/src/status-service/build/libs/status-service*.jar status-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "status-service.jar"]
CMD ["java", "-jar", "status-service.jar"]