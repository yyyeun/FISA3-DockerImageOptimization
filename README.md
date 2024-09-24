# [ Docker Image Optimization : SpringBoot 애플리케이션의 도커 이미지 최적화 ]

## 🧹 프로젝트 개요
> SpringBoot 애플리케이션을 **Distroless 베이스 이미지** 기반으로 최적화합니다. **Multi-stage build**로 JAR 파일을 컴파일한 후, **.dockerignore**를 통해 소스 코드와 불필요한 리소스를 제외하며 **Docker Slim**을 사용해 최종 이미지 크기를 최적화합니다. 이 최적화 기법들을 단계적으로 적용해 이미지 파일의 크기를 비교합니다.

<div align="center">
<img src="https://github.com/user-attachments/assets/f5384064-4159-4ab8-b16e-77ed3a278bd6" width="400">
</div>

<br>
<h2 style="font-size: 25px;"> 👨‍👨‍👧‍👦💻 팀원 <br>
<br>
    
|<img src="https://avatars.githubusercontent.com/u/64997345?v=4" width="120" height="120"/>|<img src="https://avatars.githubusercontent.com/u/38968449?v=4" width="120" height="120"/>
|:-:|:-:|
|[@최영하](https://github.com/ChoiYoungha)|[@허예은](https://github.com/yyyeun)

</h2>
<br>

## 0️⃣ 0. 실습 환경 준비
### 1. [Spring Initializr](https://start.spring.io/)에서 demo 애플리케이션 생성
<div align="center">
<img src="https://github.com/user-attachments/assets/a1110ec6-1aff-4ea8-a33c-0c14c6507c3b" width="700">
</div>
<br> 

```
curl https://start.spring.io/starter.zip \
  -d dependencies=web \
  -d type=maven-project \
  -d language=java \
  -d bootVersion=3.3.4 \
  -d groupId=com.example \
  -d artifactId=demo \
  -d name=demo \
  -d description="Demo project for Spring Boot" \
  -d packageName=com.example.demo \
  -d packaging=jar \
  -d javaVersion=17 \
  -o springboot-app.zip
```
Spring Initializr 사이트 또는 `curl` 명령어로 프로젝트 생성

<br>
<div align="center">
<img src="https://github.com/user-attachments/assets/9d404a86-c364-47c2-a843-55cc02f5464b" width="200">
<p>생성된 프로젝트 구조</p>
</div>
<br>


### 2. 테스트 서버 생성
<div align="center">
<img src="https://github.com/user-attachments/assets/58d6a128-16b2-4c63-8bf3-4c550db37e53" width="600">
</div>
<br> 

### 3. Dockerfile 작성
```
# 최적화 전 Dockerfile
# 전체 JDK 환경을 사용하여 빌드 및 실행
FROM eclipse-temurin:17-jdk-jammy

# 애플리케이션을 실행할 작업 디렉토리 설정
WORKDIR /app

# Maven 종속성 파일 및 프로젝트 파일 복사
COPY mvnw ./
COPY .mvn .mvn
COPY pom.xml ./
COPY src ./src
RUN chmod +x mvnw && ./mvnw dependency:go-offline

# 필요한 의존성 다운로드 및 패키징
RUN ./mvnw clean package -DskipTests

# 빌드된 JAR 파일 실행
CMD ["java", "-jar", "/app/target/*.jar"]
```
**최적화 전 빌드 시간:** 105.4s<br>
**최적화 전 이미지 크기:** 539MB
![image](https://github.com/user-attachments/assets/9b0e4401-623a-4f1b-8527-a6c028a3ba01)


<br> 

## 1️⃣ Optimization 1. Multi-stage build
```
# 첫 번째 스테이지: 빌드 환경
FROM openjdk:17-jdk-slim AS build-env
WORKDIR /opt/app
COPY .mvn/ .mvn
COPY mvnw pom.xml ./
RUN chmod +x mvnw && ./mvnw dependency:go-offline
RUN ./mvnw dependency:go-offline
COPY ./src ./src
RUN ./mvnw clean install

# 두번째 스테이지 : 실행 환경
FROM gcr.io/distroless/java17-debian12
WORKDIR /opt/app
EXPOSE 8080
COPY --from=build-env /opt/app/target/*.jar /opt/app/app.jar
CMD ["app.jar"]
```
**최적화 후 빌드 시간:** 81.9s<br>
**최적화 후 이미지 크기:** 245MB
![2024-09-24 23 52 07](https://github.com/user-attachments/assets/cbac30f9-912f-40bf-8978-fe5b86aba6f9)
![2024-09-24 23 53 49](https://github.com/user-attachments/assets/ce9d32c2-8107-4276-b21e-0c008c803bf9)

<br>

✨ **베이스 이미지로 Distroless를 사용하는 이유**
- **최소한의 실행 환경**: 운영 환경에서 불필요한 패키지와 도구들이 없기 때문에 이미지 크기가 매우 작고, 보안적인 장점이 큽니다.
- **JRE만 포함**: Distroless는 JDK가 아닌 JRE만 포함하므로, 애플리케이션을 실행하기 위한 최소한의 Java 환경을 제공합니다.
<br>

## 2️⃣ Optimization 2. .dockerignore 적용
```
# .dockerignore
.idea
.git
.gitignore
.dockerignore
Dockerfile
*.md
*.sh
*.yml
scripts
```
<br>

- **이미지크기 감소 및 보안강화**: 불필요한 파일을 이미지에서 제외하고 이미지 크기를 줄이고, 민감정보가 담긴 파일들을 사전에 제외함으로써 보안사고를 예방할 수 있습니다.
<br>

## 3️⃣ Optimization 3. Docker Slim (압축 도구) 실행
```
# Docker Slim 설치
wget https://github.com/slimtoolkit/slim/releases/download/1.40.11/dist_linux.tar.gz
tar -xvf ds.tar.gz
mv  dist_linux/slim /usr/local/bin/
mv  dist_linux/slim-sensor /usr/local/bin/

# 최적화 실행
docker-slim build --tag spring_optimization:2.0 spring_optimization:1.0
```
<br>

## 🎨 최종 실행 결과

<div align="center">
<img src="https://github.com/user-attachments/assets/d7cfb060-e189-4201-b78b-1bdccc715009" width="500">
<p>최적화 전과 후 도커 이미지 파일의 크기를 비교한 이미지입니다.</p>
<img src="https://github.com/user-attachments/assets/2fb1f921-cb4c-4267-ba4a-575a4e7040f1" width="500">
<p>이미지 크기가 줄어도 서비스는 정상적으로 동작한다.</p>
</div>

<br>

## 🧵 결론 및 고찰
> 리소스 절약, 배포 속도 향상, 보안 강화 등을 위해 도커 이미지 최적화가 필요하다는 것을 깨달았으며, 이미지를 최적화할 수 있는 다양한 방법들에 대해 탐구할 수 있었습니다.
