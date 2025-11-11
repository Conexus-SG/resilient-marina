#!/bin/bash

# Create OCI Log for CSV Processor
source oci-compartment.env

echo "📋 Creating OCI Log for CSV Processor..."

# Step 1: Create Log Group (if it doesn't exist)
echo "🗂️  Creating log group..."
LOG_GROUP_RESULT=$(oci logging log-group create \
  --compartment-id "$OCI_COMPARTMENT_ID" \
  --display-name "csv-processor-logs" \
  --description "Log group for CSV processor application" \
  2>/dev/null || echo "Log group may already exist")

# Get the log group OCID
if echo "$LOG_GROUP_RESULT" | grep -q "ocid1.loggroup"; then
  LOG_GROUP_OCID=$(echo "$LOG_GROUP_RESULT" | jq -r '.data.id')
  echo "✅ Created new log group: $LOG_GROUP_OCID"
else
  # Try to find existing log group
  echo "🔍 Looking for existing log group..."
  LOG_GROUP_OCID=$(oci logging log-group list \
    --compartment-id "$OCI_COMPARTMENT_ID" \
    --display-name "csv-processor-logs" \
    --query 'data[0].id' \
    --raw-output 2>/dev/null)
  
  if [[ -n "$LOG_GROUP_OCID" && "$LOG_GROUP_OCID" != "null" ]]; then
    echo "✅ Found existing log group: $LOG_GROUP_OCID"
  else
    echo "❌ Could not create or find log group. Creating with unique name..."
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    LOG_GROUP_RESULT=$(oci logging log-group create \
      --compartment-id "$OCI_COMPARTMENT_ID" \
      --display-name "csv-processor-logs-$TIMESTAMP" \
      --description "Log group for CSV processor application")
    LOG_GROUP_OCID=$(echo "$LOG_GROUP_RESULT" | jq -r '.data.id')
    echo "✅ Created log group with timestamp: $LOG_GROUP_OCID"
  fi
fi

# Step 2: Create the Log
echo "📝 Creating log..."
LOG_RESULT=$(oci logging log create \
  --log-group-id "$LOG_GROUP_OCID" \
  --display-name "csv-processor-app-log" \
  --log-type "CUSTOM" \
  --is-enabled true \
  --retention-duration 30)

if [[ $? -eq 0 ]]; then
  LOG_OCID=$(echo "$LOG_RESULT" | jq -r '.data.id')
  echo ""
  echo "🎉 Success! Log created:"
  echo "📋 Log OCID: $LOG_OCID"
  echo ""
  echo "📝 Add this to your oci-compartment.env file:"
  echo "export OCI_LOG_OCID=\"$LOG_OCID\""
  echo ""
  echo "🔧 Or add it directly:"
  echo "echo 'export OCI_LOG_OCID=\"$LOG_OCID\"' >> oci-compartment.env"
else
  echo "❌ Failed to create log. Error:"
  echo "$LOG_RESULT"
  exit 1
fi