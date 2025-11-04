# Stage 1: download APEX
FROM oraclelinux:8-slim AS builder
WORKDIR /tmp
#RUN yum install -y wget unzip && yum clean all
RUN microdnf install -y wget unzip && microdnf clean all
RUN wget https://download.oracle.com/otn_software/apex/apex_24.1.zip
RUN unzip apex_24.1.zip && rm apex_24.1.zip

# Stage 2: Oracle XE 21c met APEX
FROM container-registry.oracle.com/database/express:21.3.0-xe

USER oracle
COPY --from=builder /tmp/apex /opt/oracle/apex

# Optionele init scripts (automatisch uitgevoerd bij eerste start)
COPY scripts/ /opt/oracle/scripts/setup/

EXPOSE 1521 8080