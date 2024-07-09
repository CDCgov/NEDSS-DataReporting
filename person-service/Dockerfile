FROM amazoncorretto:17 as builder

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
FROM amazoncorretto:17
COPY --from=builder /usr/src/person-service/build/libs/person-service*.jar person-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "person-service.jar"]
CMD ["java", "-jar", "person-service.jar"]