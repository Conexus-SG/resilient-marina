#!/bin/bash

# One-step setup for OCI Instance Principal authentication
source oci-compartment.env

echo "🔧 Setting up OCI Instance Principal authentication..."
echo "📋 This will create the necessary IAM policies and dynamic groups"
echo ""

# Get tenancy OCID
TENANCY_OCID=$(oci iam compartment list --compartment-id-in-subtree true --access-level ACCESSIBLE --query 'data[?name==`root`].id | [0]' --raw-output 2>/dev/null || echo "$OCI_TENANCY")

echo "📋 Configuration:"
echo "   Tenancy: $TENANCY_OCID"
echo "   Compartment: $OCI_COMPARTMENT_ID"
echo ""

# Step 1: Create Dynamic Group
echo "👥 Creating dynamic group..."
oci iam dynamic-group create \
  --compartment-id "$TENANCY_OCID" \
  --name "csv-processor-instances" \
  --description "Dynamic group for CSV processor container instances" \
  --matching-rule "All {instance.compartment.id = '$OCI_COMPARTMENT_ID', resource.type = 'computecontainerinstance'}" \
  2>/dev/null || echo "   Dynamic group may already exist"

# Step 2: Create comprehensive policy
echo "📜 Creating comprehensive IAM policy..."
oci iam policy create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --name "csv-processor-comprehensive-policy" \
  --description "Comprehensive policy for CSV processor container instances" \
  --statements '[
    "Allow dynamic-group csv-processor-instances to use instance-principals in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to read secret-family in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to read vaults in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to use keys in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to use log-content in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to manage log-groups in compartment id '"$OCI_COMPARTMENT_ID"'",
    "Allow dynamic-group csv-processor-instances to manage logs in compartment id '"$OCI_COMPARTMENT_ID"'"
  ]' \
  2>/dev/null || echo "   Policy may already exist"

echo ""
echo "✅ Setup complete!"
echo ""
echo "📋 What was created:"
echo "   • Dynamic Group: csv-processor-instances"
echo "   • Comprehensive Policy: csv-processor-comprehensive-policy"
echo ""
echo "🔍 Verify in OCI Console:"
echo "   • Identity & Security > Dynamic Groups"
echo "   • Identity & Security > Policies"
echo ""
echo "🚀 Now redeploy your container:"
echo "   ./deploy-oci.sh"
echo ""
echo "📊 Check the logs after deployment:"
echo "   You should see successful OCI authentication messages"