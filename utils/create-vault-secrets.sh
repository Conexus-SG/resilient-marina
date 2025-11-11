#!/bin/bash

# Create secrets in OCI Vault for the CSV processor
# Make sure to source your environment variables first:
# source ../container.env

source oci-compartment.env
source .env

echo "🔐 Creating secrets in OCI Vault..."

# Create AWS Access Key secret
echo "Creating AWS Access Key secret..."
oci vault secret create-base64 \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --vault-id "$VAULT_OCID" \
  --key-id "$KEY_OCID" \
  --secret-name "$AWS_ACCESS_KEY_SECRET_NAME" \
  --secret-content-content "$(echo -n "$AWS_ACCESS_KEY_ID" | base64)" \
  --description "AWS Access Key for CSV Processor" \
  --debug

# Create AWS Secret Key secret  
echo "Creating AWS Secret Key secret..."
oci vault secret create-base64 \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --vault-id "$VAULT_OCID" \
  --key-id "$KEY_OCID" \
  --secret-name "$AWS_SECRET_ACCESS_KEY_SECRET_NAME" \
  --secret-content-content "$(echo -n "$AWS_SECRET_ACCESS_KEY" | base64)" \
  --description "AWS Secret Key for CSV Processor" \
  --debug

# Create Database Password secret
echo "Creating Database Password secret..."
oci vault secret create-base64 \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --vault-id "$VAULT_OCID" \
  --key-id "$KEY_OCID" \
  --secret-name "$DB_PASSWORD_SECRET_NAME" \
  --secret-content-content "$(echo -n "$DB_PASSWORD" | base64)" \
  --description "Oracle Database Password for CSV Processor" \
  --debug

echo "✅ Secrets created in OCI Vault!"
echo "📝 Update deploy-with-vault-secrets.sh with the actual secret OCIDs"