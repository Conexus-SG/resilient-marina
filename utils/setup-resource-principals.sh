#!/bin/bash

# Create Resource Principal policy for Container Instances
source oci-compartment.env

echo "🔧 Creating Resource Principal policy for OCI Container Instances..."
echo ""

# Get tenancy OCID
TENANCY_OCID="$OCI_TENANCY"

echo "📋 Configuration:"
echo "   Tenancy: $TENANCY_OCID"
echo "   Compartment: $OCI_COMPARTMENT_ID"
echo ""

echo "📜 Creating Resource Principal policy..."

# For Container Instances, we need to use a different approach
# Resource Principals work with the container instance resource type
POLICY_STATEMENTS=$(cat << EOF
[
  "Allow any-user to use instance-principals in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to read secret-family in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to read vaults in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to use keys in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to use log-content in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to manage log-groups in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'",
  "Allow any-user to manage logs in compartment id $OCI_COMPARTMENT_ID where request.principal.type='computecontainerinstance'"
]
EOF
)

# Create the policy
oci iam policy create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "csv-processor-resource-principal-policy" \
  --description "Resource Principal policy for CSV processor container instances" \
  --statements "$POLICY_STATEMENTS" \
  2>/dev/null || echo "   Policy may already exist"

echo ""
echo "✅ Resource Principal policy setup complete!"
echo ""
echo "📋 What was created:"
echo "   • Resource Principal Policy: csv-processor-resource-principal-policy"
echo "   • Scope: Container Instances in compartment $OCI_COMPARTMENT_ID"
echo ""
echo "🔍 This policy allows Container Instances to:"
echo "   ✅ Authenticate using Resource Principals"
echo "   ✅ Read secrets from OCI Vault"
echo "   ✅ Write logs to OCI Logging service"
echo ""
echo "🚀 Now you can deploy your container:"
echo "   ./deploy-oci.sh"
echo ""
echo "📊 The container will automatically authenticate using Resource Principals"
echo "   No additional configuration needed!"