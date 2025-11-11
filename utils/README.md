# Utilities Directory

This directory contains various utility scripts and configuration files for development, testing, and deployment of the CSV Processor application.

## 🐳 Build Scripts
- **`build.sh`** - Docker build script for Linux/macOS
- **`build.bat`** - Docker build script for Windows

## 🔧 Development & Testing Tools
- **`diagnose_wallet.py`** - Oracle wallet troubleshooting and diagnostic tool (272 lines)
- **`test_oracle_connection.py`** - Oracle database connection tester with comprehensive checks
- **`run_connection_test.py`** - Simple wrapper to run Oracle connection tests
- **`get_secret.py`** - OCI Vault secret retrieval utility for AWS credentials

## ☁️ OCI Cloud Setup Scripts
- **`setup-instance-principals.sh`** - Configure OCI instance principal authentication
- **`setup-resource-principals.sh`** - Configure OCI resource principal authentication  
- **`create-iam-policies.sh`** - Create required IAM policies for OCI deployment
- **`create-oci-log.sh`** - Set up OCI logging for the application
- **`create-vault-secrets.sh`** - Create and manage secrets in OCI Vault

## ⚙️ Configuration Files
- **`oci-compartment.env`** - OCI compartment configuration variables

**Note:** `container.env` is located in the root directory as it's used by Docker Compose.

## 📋 Usage Examples

### Test Oracle Connection
```bash
python utils/run_connection_test.py --user OAX_USER --dsn your_dsn
```

### Diagnose Wallet Issues
```bash
python utils/diagnose_wallet.py
```

### Build Docker Image
```bash
# Linux/macOS
./utils/build.sh

# Windows
./utils/build.bat
```

### Get Secret from OCI Vault
```bash
python utils/get_secret.py
```

### Setup OCI Authentication
```bash
# For instance principals
./utils/setup-instance-principals.sh

# For resource principals  
./utils/setup-resource-principals.sh
```

## 🗂️ Organization
These utilities are separated from the main application to keep the root directory clean while maintaining easy access to development and deployment tools.