# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:21-jdk-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper files
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# --- ADD THIS LINE ---
# Make the Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (this layer is cached if pom.xml doesn't change)
# Skip tests during build for faster deployment
RUN ./mvnw dependency:go-offline -DskipTests

# Copy the source code
COPY src ./src

# Package the application
RUN ./mvnw package -DskipTests

# Command to run the application using the $PORT provided by Render
CMD ["java", "-Dserver.port=${PORT}", "-jar", "target/*.jar"]
