FROM amazoncorretto:21 as builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY reporting-hydration-service /usr/src/reporting-hydration-service

#cd to root directory
WORKDIR /usr/src/

#Build service along with any required libraries
RUN ./gradlew :reporting-hydration-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
RUN yum update -y && yum clean all
COPY --from=builder /usr/src/reporting-hydration-service/build/libs/reporting-hydration-service*.jar reporting-hydration-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "reporting-hydration-service.jar"]
CMD ["java", "-jar", "reporting-hydration-service.jar"]
