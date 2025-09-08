# ====== Build stage ======
FROM gradle:8.9-jdk17 AS build
WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates wget unzip && rm -rf /var/lib/apt/lists/*

COPY build.gradle settings.gradle ./
COPY gradle ./gradle

RUN gradle dependencies --refresh-dependencies

COPY src ./src

RUN gradle clean build -x test --no-daemon \
    -Dorg.gradle.jvmargs="-Xmx2g -Djava.awt.headless=true"

# ====== Runtime stage ======
FROM eclipse-temurin:21-jre-alpine AS runtime
WORKDIR /app

RUN apk add --no-cache ca-certificates wget

RUN addgroup -S spring && adduser -S spring -G spring
USER spring

COPY --from=build /app/build/libs/*.jar /app/app.jar

ENV JAVA_OPTS="-XX:+UseZGC -XX:MaxRAMPercentage=75.0"
ENV SERVER_PORT=8080

EXPOSE 8080

HEALTHCHECK --interval=20s --timeout=3s --retries=5 --start-period=20s \
  CMD wget -qO- http://localhost:${SERVER_PORT}/actuator/health | grep -q '"status":"UP"' || exit 1

# Entry point
ENTRYPOINT ["/bin/sh","-c","java $JAVA_OPTS -jar /app/app.jar"]
