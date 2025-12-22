# Use official Python runtime as base image (x64 architecture)
FROM --platform=linux/amd64 python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies for Oracle Instant Client
RUN apt-get update && apt-get install -y \
    libaio1 \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Oracle Instant Client
RUN mkdir -p /opt/oracle && \
    cd /opt/oracle && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1919000/instantclient-basic-linux.x64-19.19.0.0.0dbru.zip && \
    unzip instantclient-basic-linux.x64-19.19.0.0.0dbru.zip && \
    rm instantclient-basic-linux.x64-19.19.0.0.0dbru.zip && \
    mv instantclient_19_19 instantclient && \
    mkdir -p /opt/oracle/instantclient/network/admin && \
    echo /opt/oracle/instantclient > /etc/ld.so.conf.d/oracle-instantclient.conf && \
    ldconfig

# Set Oracle environment variables
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient:$LD_LIBRARY_PATH
ENV ORACLE_HOME=/opt/oracle/instantclient

# Copy requirements file
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY download_csv_from_s3.py .
COPY download_stellar_from_s3.py .
COPY molo_db_functions.py .
COPY stellar_db_functions.py .
COPY data_validator.py .
COPY config.json .
COPY wallet/ ./wallet/

# Copy wallet files to Oracle Instant Client network/admin directory (like rosnet does)
COPY wallet/tnsnames.ora /opt/oracle/instantclient/network/admin/tnsnames.ora
COPY wallet/sqlnet.ora /opt/oracle/instantclient/network/admin/sqlnet.ora
COPY wallet/cwallet.sso /opt/oracle/instantclient/network/admin/cwallet.sso
COPY wallet/ewallet.p12 /opt/oracle/instantclient/network/admin/ewallet.p12

# Also keep wallet in app directory for backward compatibility
COPY wallet/sqlnet.ora ./wallet/sqlnet.ora

# Set environment variables for containerized operation BEFORE user switch
ENV PYTHONUNBUFFERED=1
ENV TNS_ADMIN=/opt/oracle/instantclient/network/admin

# Create non-root user for security
RUN useradd --create-home --shell /bin/bash appuser && \
    chown -R appuser:appuser /app && \
    chmod -R 755 /app/wallet && \
    chmod 644 /opt/oracle/instantclient/network/admin/* && \
    ls -la /opt/oracle/instantclient/network/admin/

USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import oracledb; print('Health check passed')" || exit 1

# Default command - run the full ETL process
ENTRYPOINT ["python", "download_csv_from_s3.py"]
CMD []