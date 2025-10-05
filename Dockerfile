# ---- Stage 1: Build ----
FROM openjdk:8-jdk AS build

WORKDIR /app

# Install Ant and other dependencies
RUN apt-get update && apt-get install -y ant wget unzip && rm -rf /var/lib/apt/lists/*

# Download javax.servlet-api for compilation
RUN wget https://repo1.maven.org/maven2/javax/servlet/javax.servlet-api/4.0.1/javax.servlet-api-4.0.1.jar -O /app/javax.servlet-api-4.0.1.jar

# Copy source code and libraries
COPY ch12_ex1_sqlGateway /app/ch12_ex1_sqlGateway
COPY ch12_ex2_userAdmin /app/ch12_ex2_userAdmin
COPY libs /app/libs

# ========================
# Build ch12_ex1_sqlGateway
# ========================
WORKDIR /app/ch12_ex1_sqlGateway

# Copy libraries to WEB-INF/lib
RUN cp -r /app/libs/* web/WEB-INF/lib/ 2>/dev/null || true

# Create necessary directories
RUN mkdir -p build/web/WEB-INF/classes && \
    mkdir -p build/web/META-INF && \
    mkdir -p dist

# Copy web files to build directory
RUN cp -r web/* build/web/ 2>/dev/null || true

# Compile Java files
RUN find src -name "*.java" > sources.txt && \
    mkdir -p build/classes && \
    javac -cp "/app/javax.servlet-api-4.0.1.jar:/app/libs/*:web/WEB-INF/lib/*" \
          -d build/classes \
          @sources.txt

# Create WAR file - FIXED: ensure proper directory structure
RUN cd build/web && jar cf ../../dist/ch12_ex1_sqlGateway.war .
RUN cd build/classes && jar uf ../../dist/ch12_ex1_sqlGateway.war .

# ========================
# Build ch12_ex2_userAdmin  
# ========================
WORKDIR /app/ch12_ex2_userAdmin

# Copy libraries to WEB-INF/lib
RUN cp -r /app/libs/* web/WEB-INF/lib/ 2>/dev/null || true

# Create necessary directories
RUN mkdir -p build/web/WEB-INF/classes && \
    mkdir -p build/web/META-INF && \
    mkdir -p dist

# Copy web files to build directory
RUN cp -r web/* build/web/ 2>/dev/null || true

# Compile Java files
RUN find src -name "*.java" > sources.txt && \
    mkdir -p build/classes && \
    javac -cp "/app/javax.servlet-api-4.0.1.jar:/app/libs/*:web/WEB-INF/lib/*" \
          -d build/classes \
          @sources.txt

# Create WAR file - FIXED: ensure proper directory structure
RUN cd build/web && jar cf ../../dist/ch12_ex2_userAdmin.war .
RUN cd build/classes && jar uf ../../dist/ch12_ex2_userAdmin.war .

# ---- Stage 2: Run ----
FROM tomcat:9-jdk11-openjdk

# Create necessary directories
RUN mkdir -p /usr/local/tomcat/webapps

# Configure Tomcat for Render
RUN sed -i 's/port="8080"/port="${PORT:-8080}"/' /usr/local/tomcat/conf/server.xml

# Copy WAR files to Tomcat
COPY --from=build /app/ch12_ex1_sqlGateway/dist/ch12_ex1_sqlGateway.war /usr/local/tomcat/webapps/ROOT.war
COPY --from=build /app/ch12_ex2_userAdmin/dist/ch12_ex2_userAdmin.war /usr/local/tomcat/webapps/admin.war

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

EXPOSE 8080

# Use the PORT environment variable provided by Render
CMD ["sh", "-c", "catalina.sh run"]