# =========================
# Stage 1: Build with Ant
# =========================
FROM openjdk:8-jdk as builder

# Cài ant
RUN apt-get update && apt-get install -y ant && rm -rf /var/lib/apt/lists/*

# Làm việc trong /app
WORKDIR /app

# Copy project và thư viện
COPY ch12_ex1_sqlGateway /app/ch12_ex1_sqlGateway
COPY ch12_ex2_userAdmin /app/ch12_ex2_userAdmin
COPY libs /app/libs

# Build WAR
WORKDIR /app/ch12_ex1_sqlGateway
RUN ant clean dist

WORKDIR /app/ch12_ex2_userAdmin
RUN ant clean dist

# =========================
# Stage 2: Run with Tomcat
# =========================
FROM tomcat:9.0-jdk8

# Xóa webapps mặc định
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file vào Tomcat
COPY --from=builder /app/ch12_ex1_sqlGateway/dist/ch12_ex1_sqlGateway.war /usr/local/tomcat/webapps/ch12_ex1_sqlGateway.war
COPY --from=builder /app/ch12_ex2_userAdmin/dist/ch12_ex2_userAdmin.war /usr/local/tomcat/webapps/ch12_ex2_userAdmin.war

# Render cung cấp PORT qua biến môi trường
ENV PORT=10000

# Tomcat mặc định dùng 8080 → ta chỉnh lại thành $PORT
RUN sed -i 's/8080/${PORT}/g' /usr/local/tomcat/conf/server.xml

# Expose cổng do Render yêu cầu
EXPOSE 10000

# Start Tomcat
CMD ["catalina.sh", "run"]
