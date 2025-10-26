# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:21-jdk-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper files
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Download dependencies (this layer is cached if pom.xml doesn't change)
# Skip tests during build for faster deployment
RUN ./mvnw dependency:go-offline -DskipTests

# Copy the source code
COPY src ./src

# Package the application
RUN ./mvnw package -DskipTests

# Expose the port the app runs on (Render provides $PORT)
# EXPOSE 8080 (Render injects PORT env var, so this isn't strictly needed)

# Command to run the application using the $PORT provided by Render
# java -jar target/*.jar would also work if PORT default is 8080
CMD ["java", "-Dserver.port=${PORT}", "-jar", "target/*.jar"]
