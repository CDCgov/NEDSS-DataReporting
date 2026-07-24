FROM amazoncorretto:21 AS builder
WORKDIR /usr/src/
# findutils: gradlew requires xargs, which current amazoncorretto:21 no longer ships
RUN yum update -y && yum install -y findutils && yum clean all

#Copy project config
COPY gradle gradle
COPY gradlew gradlew
COPY settings.gradle settings.gradle

# Copy only the build files needed to resolve dependencies
COPY reporting-pipeline-service/build.gradle reporting-pipeline-service/build.gradle
# Download dependencies as a separate cached layer
RUN ./gradlew :reporting-pipeline-service:dependencies --no-daemon

# Now copy the actual source code (changes frequently)
COPY reporting-pipeline-service/lombok.config reporting-pipeline-service/lombok.config
COPY reporting-pipeline-service/src reporting-pipeline-service/src
# Build
RUN ./gradlew :reporting-pipeline-service:buildNeeded -x test --no-daemon

FROM amazoncorretto:21
WORKDIR /
# unpinned + --allowerasing: the base image now ships a conflicting
# curl-minimal, and the pinned 8.3.0 is no longer in the repos
RUN yum update -y && yum install -y --allowerasing curl && yum clean all

COPY --from=builder /usr/src/reporting-pipeline-service/build/libs/reporting-pipeline-service*.jar reporting-pipeline-service.jar

HEALTHCHECK --start-period=5s --timeout=10s \
  CMD curl -f http://localhost:8095/actuator/health || exit 1

# Run jar
ENTRYPOINT ["java", "-jar", "reporting-pipeline-service.jar"]
