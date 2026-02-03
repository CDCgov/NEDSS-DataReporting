FROM amazoncorretto:25 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY organization-service /usr/src/organization-service

#cd to root
WORKDIR /usr/src/

#Build person service along with any required libraries
RUN ./gradlew :organization-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:25
RUN yum update -y && yum clean all
COPY --from=builder /usr/src/organization-service/build/libs/organization-service*.jar organization-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "organization-service.jar"]
CMD ["java", "-jar", "organization-service.jar"]