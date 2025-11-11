# Marina Data Processing Pipeline - Docker Containerized Application

A Docker containerized application that downloads and processes marina management data from two sources:
- **MOLO System**: ZIP files containing marina, pier, slip, and reservation data
- **Stellar Business**: Gzipped DATA files with booking, customer, and sales data

The application synchronizes data with Oracle Autonomous Database using MERGE operations to prevent duplication.

## 🏗️ Architecture

- **Base Image**: Python 3.11-slim
- **Oracle Client**: Oracle Instant Client 19.19
- **Dependencies**: boto3, oracledb, python-dotenv
- **Security**: Runs as non-root user
- **Health Checks**: Built-in liveness and readiness probes
- **Data Sources**: MOLO (47 tables) + Stellar Business (29 tables)

## 📋 Prerequisites

- Docker Engine 20.10+
- Docker Compose 2.0+
- AWS credentials (for S3 access)
- Oracle Autonomous Database wallet files
- Kubernetes cluster (for OCI deployment)

## 🚀 Quick Start

### 1. Configure Environment

Copy the environment template and fill in your values:
```bash
cp .env.template .env
# Edit .env with your AWS and Oracle credentials
```

**Required environment variables:**
```bash
# AWS Configuration
AWS_ACCESS_KEY_ID=your_access_key
AWS_SECRET_ACCESS_KEY=your_secret_key

# S3 Configuration for MOLO data
S3_BUCKET=cnxtestbucket
S3_REGION=us-east-1

# S3 Configuration for Stellar data
STELLAR_S3_BUCKET=resilient-ims-backups

# Oracle Database
DB_USER=OAX_USER
DB_PASSWORD=your_password
DB_DSN=your_dsn_low
```

### 2. Build the Container

**Linux/macOS:**
```bash
chmod +x build.sh
./build.sh
```

**Windows:**
```cmd
build.bat
```

### 3. Run with Docker

**Process both MOLO and Stellar data:**
```bash
docker run --env-file .env csv-processor:latest
```

**Process only MOLO data:**
```bash
docker run --env-file .env csv-processor:latest --process-molo --no-process-stellar
```

**Process only Stellar data:**
```bash
docker run --env-file .env csv-processor:latest --no-process-molo --process-stellar
```

**With Docker Compose:**
```bash
docker-compose up
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key | Required |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Key | Required |
| `AWS_DEFAULT_REGION` | AWS Region | us-east-1 |
| `DB_USER` | Oracle Username | OAX_USER |
| `DB_PASSWORD` | Oracle Password | Required |
| `DB_DSN` | Oracle DSN | oax5007253621_low |
| `S3_BUCKET` | S3 Bucket Name | cnxtestbucket |
| `S3_KEY` | S3 Object Key | test-csv.zip |
| `S3_REGION` | S3 Region | us-east-1 |

### Command Line Arguments

```bash
python download_csv_from_s3.py [OPTIONS]

Options:
  --bucket TEXT     S3 bucket name
  --key TEXT        S3 object key
  --region TEXT     AWS region
  --db-user TEXT    Oracle username
  --db-password TEXT Oracle password
  --db-dsn TEXT     Oracle DSN
  --db-only         Insert to database (vs. print only)
  --help            Show help message
```

## ☁️ OCI Deployment

### Container Registry

**Push to OCI Registry:**
```bash
# Tag for OCI registry
docker tag csv-processor:latest \
  <region>.ocir.io/<tenancy>/csv-processor:latest

# Login to OCI registry
docker login <region>.ocir.io

# Push image
docker push <region>.ocir.io/<tenancy>/csv-processor:latest
```

### Kubernetes Deployment

**Deploy to OCI Container Engine (OKE):**
```bash
# Update secrets in k8s-deployment.yaml
kubectl apply -f k8s-deployment.yaml

# Check deployment status
kubectl get pods -l app=csv-processor

# View logs
kubectl logs -l app=csv-processor -f
```

### OCI Container Instances

**Run as OCI Container Instance:**
```bash
oci container-instances container-instance create \
  --compartment-id <compartment-id> \
  --availability-domain <availability-domain> \
  --display-name csv-processor \
  --shape CI.Standard.E4.Flex \
  --shape-config '{"memoryInGBs": 1, "ocpus": 0.5}' \
  --containers '[{
    "displayName": "csv-processor",
    "imageUrl": "<region>.ocir.io/<tenancy>/csv-processor:latest",
    "environmentVariables": {
      "AWS_ACCESS_KEY_ID": "<your-key>",
      "AWS_SECRET_ACCESS_KEY": "<your-secret>",
      "DB_USER": "OAX_USER",
      "DB_PASSWORD": "<your-password>",
      "DB_DSN": "oax5007253621_low"
    }
  }]'
```

## 🔒 Security

### Best Practices Implemented

- ✅ **Non-root user**: Runs as user ID 1000
- ✅ **Read-only filesystem**: Where possible
- ✅ **Secret management**: Credentials via environment variables/Kubernetes secrets
- ✅ **Resource limits**: CPU and memory constraints
- ✅ **Health checks**: Liveness and readiness probes
- ✅ **Minimal base image**: Python slim variant

## 📊 Monitoring

### Health Checks

**Docker:**
```bash
# Check container health
docker ps --format "table {{.Names}}\t{{.Status}}"
```

**Kubernetes:**
```bash
# Check pod health
kubectl get pods -l app=csv-processor

# View health check logs
kubectl describe pod <pod-name>
```

## 🔄 Scheduled Execution

### Kubernetes CronJob

The provided `k8s-deployment.yaml` includes a CronJob that runs every 6 hours:
```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: csv-processor-cron
spec:
  schedule: "0 */6 * * *"
```

## 🛠️ Troubleshooting

### Common Issues

**Oracle Client Errors:**
```bash
# Check Oracle client installation
docker run csv-processor:latest python -c "import oracledb; print('OK')"
```

**Wallet Issues:**
```bash
# Verify wallet files
docker run csv-processor:latest ls -la /app/wallet_demo/
```

## 📈 Legacy Usage (Non-Docker)

### Prerequisites

- Python 3.6+
- An AWS account with an S3 bucket and a file to download.
- AWS credentials configured in your environment.

## Setup

1.  **Clone the repository:**
    ```bash
    git clone <repository-url>
    cd aws-retrieve-csv
    ```

2.  **Install dependencies:**
    ```bash
    pip install -r requirements.txt
    ```

3.  **Configure AWS Credentials:**

    Create a `.env` file in the root of the project and add your AWS credentials:
    ```
    AWS_ACCESS_KEY_ID="YOUR_AWS_ACCESS_KEY_ID"
    AWS_SECRET_ACCESS_KEY="YOUR_AWS_SECRET_ACCESS_KEY"
    ```
    Alternatively, you can configure credentials using any of the other methods supported by `boto3` (e.g., `~/.aws/credentials` file).

## Usage

You can run the script with command-line arguments to specify the S3 bucket, file key, local filename, and AWS region.

```bash
python download_csv_from_s3.py [--bucket BUCKET] [--key KEY] [--file FILE] [--region REGION]
```

### Arguments

-   `--bucket`: The name of the S3 bucket (default: `cnxtestbucket`).
-   `--key`: The key (path) of the file in the S3 bucket (default: `test-csv.csv`).
-   `--file`: The local filename to save the downloaded file (default: `downloaded_data.csv`).
-   `--region`: The AWS region of the bucket (default: `us-east-1`).

### Example

```bash
python download_csv_from_s3.py --bucket my-awesome-bucket --key data/my-file.csv --file my_local_file.csv --region us-west-2
```

If you run the script without any arguments, it will use the default values.
```bash
python download_csv_from_s3.py
```

## Testing

This project uses `pytest` for testing. The tests are located in the `test_download.py` file and use `moto` to mock AWS services.

To run the tests, execute the following command in the root of the project:
```bash
pytest
```
