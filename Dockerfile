# 첫 번째 스테이지: 빌드 환경
FROM eclipse-temurin:17-jdk-jammy AS builder

WORKDIR /app

# Maven 종속성 파일 복사 및 의존성 다운로드
COPY mvnw ./mvnw
COPY .mvn .mvn
COPY pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline

# 소스 코드 복사 및 빌드
COPY src ./src
RUN ./mvnw clean package -DskipTests

# 두 번째 스테이지: 실행 환경 (Distroless)
FROM gcr.io/distroless/java17-debian11

WORKDIR /app

# 빌드된 JAR 파일만 복사
COPY --from=builder /app/target/*.jar /app/app.jar

# 애플리케이션 실행
CMD ["java", "-jar", "/app/app.jar"]

