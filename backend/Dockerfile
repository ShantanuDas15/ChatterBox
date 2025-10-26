# Use an official OpenJDK runtime as a parent image
FROM eclipse-temurin:21-jdk-jammy

# Set the working directory inside the container
WORKDIR /app

# Copy the Maven wrapper files
COPY .mvn/ .mvn
COPY mvnw pom.xml ./

# Make the Maven wrapper executable
RUN chmod +x mvnw

# Download dependencies (this layer is cached if pom.xml doesn't change)
RUN ./mvnw dependency:go-offline -DskipTests

# Copy the source code
COPY src ./src

# Package the application
RUN ./mvnw package -DskipTests

# --- THIS IS THE CORRECTED LINE ---
# Command to run the application, specifying the exact jar file
CMD ["java", "-Dserver.port=${PORT}", "-jar", "target/backend-0.0.1-SNAPSHOT.jar"]
