FROM amazoncorretto:21 as builder

#Copy project config
COPY gradle /usr/src/gradle
COPY gradlew /usr/src/gradlew
COPY settings.gradle /usr/src/settings.gradle

#Copy sources
COPY common-util /usr/src/common-util
COPY ldfdata-service /usr/src/ldfdata-service

#cd to ldfdata-service
WORKDIR /usr/src/

#Build person service along with any required libraries
RUN ./gradlew :ldfdata-service:buildNeeded -x test --no-daemon
FROM amazoncorretto:21
COPY --from=builder /usr/src/ldfdata-service/build/libs/ldfdata-service*.jar ldfdata-service.jar

# Run jar
ENTRYPOINT ["java", "-jar", "ldfdata-service.jar"]
CMD ["java", "-jar", "ldfdata-service.jar"]