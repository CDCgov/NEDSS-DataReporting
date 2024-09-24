FROM amazoncorretto:21 as builder

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
FROM amazoncorretto:21
COPY --from=builder /usr/src/observation-service/build/libs/observation-service*.jar observation-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "observation-service.jar"]
CMD ["java", "-jar", "observation-service.jar"]