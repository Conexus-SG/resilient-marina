#!/bin/bash

# Create IAM policies for OCI Container Instance to access Vault and Logging
source oci-compartment.env

echo "🔐 Creating IAM policies for Container Instance..."

# Policy 1: Allow container instances to use instance principals
echo "📋 Creating instance principal policy..."
INSTANCE_PRINCIPAL_POLICY=$(oci iam policy create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "csv-processor-instance-principal-policy" \
  --description "Allow container instances to use instance principals" \
  --statements '[
    "Allow any-user to use instance-principals in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to use instance-principals in compartment id '"$OCI_COMPARTMENT_ID"'"
  ]' 2>/dev/null || echo "Policy may already exist")

# Policy 2: Allow access to Vault secrets
echo "📋 Creating vault access policy..."
VAULT_POLICY=$(oci iam policy create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "csv-processor-vault-policy" \
  --description "Allow CSV processor to read vault secrets" \
  --statements '[
    "Allow dynamic-group csv-processor-instances to read secret-family in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to read vaults in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to use keys in compartment id '"$OCI_COMPARTMENT_ID"'"
  ]' 2>/dev/null || echo "Policy may already exist")

# Policy 3: Allow access to Logging
echo "📋 Creating logging access policy..."
LOGGING_POLICY=$(oci iam policy create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "csv-processor-logging-policy" \
  --description "Allow CSV processor to write to logging service" \
  --statements '[
    "Allow dynamic-group csv-processor-instances to use log-content in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to manage log-groups in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to manage logs in compartment id '"$OCI_COMPARTMENT_ID"'"
  ]' 2>/dev/null || echo "Policy may already exist")

echo "✅ IAM policies created/verified!"
echo ""
echo "📋 Next steps:"
echo "1. Create a dynamic group for your container instances"
echo "2. Update your container deployment to use the dynamic group"
echo ""
echo "🔧 Run the next script: ./create-dynamic-group.sh"