FROM amazoncorretto:21 AS builder

RUN yum update -y && yum clean all

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY reporting-pipeline-service /usr/src/reporting-pipeline-service

#cd to root directory
WORKDIR /usr/src/

#Build service along with any required libraries
RUN ./gradlew :reporting-pipeline-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
RUN yum update -y && yum install -y curl && yum clean all
COPY --from=builder /usr/src/reporting-pipeline-service/build/libs/reporting-pipeline-service*.jar reporting-pipeline-service.jar
COPY reporting-pipeline-service/entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

HEALTHCHECK --start-period=5s --timeout=10s \
  CMD curl -f http://localhost:8095/actuator/health || exit 1

ENTRYPOINT ["./entrypoint.sh"]
