# Multi-stage Dockerfile for Oracle APEX on Oracle XE
# This allows you to build and host your own images with APEX pre-installed

# Build arguments
ARG ORACLE_VERSION=21.3.0-xe
ARG APEX_VERSION=24.2

# Stage 1: Download APEX
FROM oraclelinux:8-slim AS builder

ARG APEX_VERSION
ARG APEX_DOWNLOAD_URL=https://download.oracle.com/otn_software/apex/apex_${APEX_VERSION}.zip

WORKDIR /tmp
RUN microdnf install -y curl unzip && microdnf clean all

# Download and extract APEX
RUN echo "Downloading APEX ${APEX_VERSION} from ${APEX_DOWNLOAD_URL}" && \
    curl -o apex.zip ${APEX_DOWNLOAD_URL} && \
    unzip -q apex.zip && \
    rm apex.zip

# Stage 2: Oracle XE with APEX
ARG ORACLE_VERSION
FROM container-registry.oracle.com/database/express:${ORACLE_VERSION}

ARG APEX_VERSION
ARG ORACLE_VERSION

# Add labels for version tracking
LABEL apex.version="${APEX_VERSION}"
LABEL oracle.version="${ORACLE_VERSION}"
LABEL maintainer="your-team@example.com"

# Copy APEX from builder stage
USER oracle
COPY --from=builder /tmp/apex /opt/oracle/apex

# Copy setup scripts and configuration
COPY --chown=oracle:oinstall scripts/ /opt/oracle/scripts/setup/
COPY --chown=oracle:oinstall config/ /opt/oracle/config/

EXPOSE 1521

# Default command will be overridden by docker-compose
CMD ["/opt/oracle/scripts/setup/db-entrypoint-wrapper.sh"]
