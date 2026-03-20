FROM amazoncorretto:21 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY person-service /usr/src/person-service

#cd to root directory
WORKDIR /usr/src/

#Build person service along with any required libraries
RUN ./gradlew :person-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
RUN yum update -y && yum install -y curl && yum clean all
COPY --from=builder /usr/src/person-service/build/libs/person-service*.jar person-service.jar

HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD curl -f http://localhost:8095/actuator/health || exit 1

# Run jar
ENTRYPOINT ["java", "-jar", "person-service.jar"]
CMD ["java", "-jar", "person-service.jar"]
