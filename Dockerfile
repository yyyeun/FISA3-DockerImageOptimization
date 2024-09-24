FROM openjdk:17-jdk-slim AS build-env
WORKDIR /opt/app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline
RUN ./mvnw dependency:go-offline
COPY ./src ./src
RUN ./mvnw clean install

FROM gcr.io/distroless/java17-debian12
WORKDIR /opt/app
EXPOSE 8080
COPY --from=build-env /opt/app/target/*.jar /opt/app/app.jar
CMD ["app.jar"]