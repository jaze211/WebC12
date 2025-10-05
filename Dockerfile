# ---- Stage 1: Build ----
FROM openjdk:8-jdk AS build

WORKDIR /app

# Install Ant and wget (for downloading dependencies)
RUN apt-get update && apt-get install -y ant wget && rm -rf /var/lib/apt/lists/*

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

# Patch MySQLDriver path in project.properties
RUN sed -i 's|^libs.MySQLDriver.classpath=.*|libs.MySQLDriver.classpath=/app/libs/mysql-connector-java-5.1.23-bin.jar|' nbproject/project.properties

RUN ant clean dist \
    -Dlibs.dir=/app/libs \
    -Dservlet-api.jar=/app/javax.servlet-api-4.0.1.jar \
    -Dlibs.CopyLibs.classpath=/app/libs/org-netbeans-modules-java-j2seproject-copylibstask.jar \
    -Dlibs.jstl.classpath=/app/libs/jstl-1.2.jar \
    -Dlibs.MySQLDriver.classpath=/app/libs/mysql-connector-java-5.1.23-bin.jar

# ========================
# Build ch12_ex2_userAdmin
# ========================
WORKDIR /app/ch12_ex2_userAdmin

# Patch MySQLDriver path in project.properties
RUN sed -i 's|^libs.MySQLDriver.classpath=.*|libs.MySQLDriver.classpath=/app/libs/mysql-connector-java-5.1.23-bin.jar|' nbproject/project.properties

RUN ant clean dist \
    -Dlibs.dir=/app/libs \
    -Dservlet-api.jar=/app/javax.servlet-api-4.0.1.jar \
    -Dlibs.CopyLibs.classpath=/app/libs/org-netbeans-modules-java-j2seproject-copylibstask.jar \
    -Dlibs.jstl.classpath=/app/libs/jstl-1.2.jar \
    -Dlibs.MySQLDriver.classpath=/app/libs/mysql-connector-java-5.1.23-bin.jar

# ---- Stage 2: Run ----
FROM tomcat:9-jdk11-openjdk

# Configure Tomcat to use Render's $PORT (fallback to 8080)
RUN sed -i 's/port="8080"/port="${connector.port}"/' /usr/local/tomcat/conf/server.xml
RUN echo '#!/bin/sh' > /usr/local/tomcat/bin/setenv.sh && \
    echo 'if [ -z "$PORT" ]; then' >> /usr/local/tomcat/bin/setenv.sh && \
    echo '  PORT=8080' >> /usr/local/tomcat/bin/setenv.sh && \
    echo 'fi' >> /usr/local/tomcat/bin/setenv.sh && \
    echo 'CATALINA_OPTS="$CATALINA_OPTS -Dconnector.port=$PORT"' >> /usr/local/tomcat/bin/setenv.sh && \
    chmod +x /usr/local/tomcat/bin/setenv.sh

# Copy WAR files to Tomcat webapps
COPY --from=build /app/ch12_ex1_sqlGateway/dist/ch12_ex1_sqlGateway.war /usr/local/tomcat/webapps/ch12_ex1_sqlGateway.war
COPY --from=build /app/ch12_ex2_userAdmin/dist/ch12_ex2_userAdmin.war /usr/local/tomcat/webapps/ch12_ex2_userAdmin.war

EXPOSE 8080
CMD ["catalina.sh", "run"]
