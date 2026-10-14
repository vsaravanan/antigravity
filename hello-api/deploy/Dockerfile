# Use OpenJDK 26 runtime image
FROM docker.io/library/eclipse-temurin:26-jre-alpine

# Set working directory
WORKDIR /app

# Copy the JAR file
COPY target/hello-api.jar /app/hello-api.jar

# Expose port 8000
EXPOSE 8000

# Run the application
ENTRYPOINT ["java", "-jar", "/app/hello-api.jar"]
