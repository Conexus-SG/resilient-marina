#!/bin/bash

# OCI Deployment Script for CSV Processor
set -e

# Load environment variables from .env file if it exists
if [[ -f ".env" ]]; then
    echo "📋 Loading environment variables from .env file..."
    # Export all environment variables from .env (skip comments and empty lines)
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    echo "✅ Environment variables loaded"
else
    echo "⚠️  Warning: .env file not found. Make sure AWS credentials are set."
fi

source utils/oci-compartment.env
source .env

# Optional: Add compartment-specific repository naming
COMPARTMENT_NAME="${COMPARTMENT_NAME:-resilient-marinas}"
if [[ -n "$COMPARTMENT_NAME" ]]; then
    IMAGE_NAME="${COMPARTMENT_NAME}/${IMAGE_NAME}"
fi
OCI_AVAILABILITY_DOMAIN="${OCI_AVAILABILITY_DOMAIN:-BCpN:US-CHICAGO-1-AD-1}"
OCI_SUBNET_ID="${OCI_SUBNET_ID:-ocid1.subnet.oc1.us-chicago-1.aaaaaaaab6sl3mlk4px56dyqe6th4twnq7mbnnrtkvjwcuuwby5f7jgasria}"
REGISTRY_URL="${OCI_REGION}.ocir.io"

# For OCI Container Registry, the URL format is:
# region.ocir.io/tenancy-namespace/repository-name/image:tag
# Where tenancy-namespace is the same as your Container Registry namespace

# Use the namespace directly as the tenancy identifier for the registry
FULL_IMAGE_NAME="${REGISTRY_URL}/${OCI_NAMESPACE}/${IMAGE_NAME}:${VERSION}"

# Validate that we have all required components
if [[ -z "$OCI_NAMESPACE" ]]; then
    echo "❌ Error: Missing OCI_NAMESPACE"
    echo "Please set your Container Registry namespace"
    echo "Find it in: OCI Console > Developer Services > Container Registry"
    exit 1
fi

# Debug output
echo "🔍 Configuration Debug:"
echo "OCI_TENANCY: ${OCI_TENANCY}"
echo "OCI_NAMESPACE: ${OCI_NAMESPACE}"
echo "REGISTRY_URL: ${REGISTRY_URL}"
echo "FULL_IMAGE_NAME: ${FULL_IMAGE_NAME}"
echo ""

echo "🚀 Deploying CSV Processor to OCI"
echo "=================================="
echo "Registry: ${REGISTRY_URL}"
echo "Image: ${FULL_IMAGE_NAME}"
echo ""

# Step 1: Build the image
echo "📦 Building Docker image for x64 architecture..."
docker build --platform linux/amd64 -t ${IMAGE_NAME}:${VERSION} .

# Step 2: Tag for OCI Registry
echo "🏷️  Tagging image for OCI Registry..."
docker tag ${IMAGE_NAME}:${VERSION} ${FULL_IMAGE_NAME}

# Step 3: Login to OCI Registry
echo "🔑 Logging into OCI Registry..."
echo "Registry URL: ${REGISTRY_URL}"
echo ""
echo "Login credentials format:"
echo "Username: ${OCI_NAMESPACE}/<your-oci-username>"
echo "Password: <your-auth-token>"
echo ""
echo "Example:"
echo "Username: ax9rooil0bn8/john.doe@company.com"
echo "Password: your-auth-token-here"
echo ""
read -p "Press Enter to continue with docker login to ${REGISTRY_URL}..."
docker login ${REGISTRY_URL}

# Step 4: Push to OCI Registry
echo "📤 Pushing image to OCI Registry..."
docker push ${FULL_IMAGE_NAME}

# Step 5: Deploy to OCI Container Instances (optional)
read -p "Do you want to deploy to OCI Container Instances? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "🚀 Deploying to OCI Container Instances..."
    echo ""
    
    # Check if required environment variables are set
    if [[ -z "$OCI_COMPARTMENT_ID" ]]; then
        echo "📋 Available compartments:"
        echo "Getting compartment list... (this may take a moment)"
        
        # Try to list compartments if OCI CLI is configured
        if oci iam compartment list --compartment-id-in-subtree true --access-level ACCESSIBLE 2>/dev/null | head -20; then
            echo ""
            echo "💡 Tip: Use the OCID from the 'id' column above"
        else
            echo "❌ Could not list compartments. Please ensure OCI CLI is configured."
            echo "💡 Find compartments in: OCI Console > Identity & Security > Compartments"
        fi
        echo ""
        read -p "Enter OCI Compartment OCID: " OCI_COMPARTMENT_ID
        
        # Validate compartment OCID format
        if [[ ! "$OCI_COMPARTMENT_ID" =~ ^ocid1\.compartment\.oc1\. ]] && [[ ! "$OCI_COMPARTMENT_ID" =~ ^ocid1\.tenancy\.oc1\. ]]; then
            echo "⚠️  Warning: This doesn't look like a valid compartment OCID"
            echo "   Expected format: ocid1.compartment.oc1..<unique-id>"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Deployment cancelled."
                exit 1
            fi
        fi
    fi
    
    if [[ -z "$OCI_AVAILABILITY_DOMAIN" ]]; then
        echo "🏢 Available availability domains:"
        echo "Getting availability domains for compartment..."
        
        # Try to list availability domains
        if oci iam availability-domain list --compartment-id "$OCI_COMPARTMENT_ID" 2>/dev/null; then
            echo ""
        else
            echo "❌ Could not list availability domains."
            echo "💡 Common format: {REGION}-AD-1, {REGION}-AD-2, {REGION}-AD-3"
            echo "💡 Example: US-CHICAGO-1-AD-1"
        fi
        echo ""
        read -p "Enter Availability Domain: " OCI_AVAILABILITY_DOMAIN
    fi
    
    # Get subnet information
    if [[ -z "$OCI_SUBNET_ID" ]]; then
        echo ""
        echo "🌐 Available subnets:"
        echo "Getting subnet list for compartment..."
        
        # Try to list subnets
        if oci network subnet list --compartment-id "$OCI_COMPARTMENT_ID" 2>/dev/null; then
            echo ""
            echo "💡 Choose a subnet from the list above"
        else
            echo "❌ Could not list subnets."
            echo "💡 Find subnets in: OCI Console > Networking > Virtual Cloud Networks"
            echo "💡 Format: ocid1.subnet.oc1.region.unique-id"
        fi
        echo ""
        read -p "Enter Subnet OCID: " OCI_SUBNET_ID
        
        # Validate subnet OCID format
        if [[ ! "$OCI_SUBNET_ID" =~ ^ocid1\.subnet\.oc1\. ]]; then
            echo "⚠️  Warning: This doesn't look like a valid subnet OCID"
            echo "   Expected format: ocid1.subnet.oc1..<unique-id>"
            read -p "Continue anyway? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo "Deployment cancelled."
                exit 1
            fi
        fi
    fi
    
    echo ""
    echo "📋 Deployment Configuration:"
    echo "Compartment: ${OCI_COMPARTMENT_ID}"
    echo "Availability Domain: ${OCI_AVAILABILITY_DOMAIN}"
    echo "Subnet: ${OCI_SUBNET_ID}"
    echo "Image: ${FULL_IMAGE_NAME}"
    echo ""
    read -p "Proceed with deployment? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
    
    # Create container instance with VNICs
    echo "🚀 Creating container instance..."
    echo "📋 Final configuration check:"
    echo "  Compartment: ${OCI_COMPARTMENT_ID}"
    echo "  Availability Domain: ${OCI_AVAILABILITY_DOMAIN}"
    echo "  Subnet: ${OCI_SUBNET_ID}"
    echo "  Image: ${FULL_IMAGE_NAME}"
    echo ""
    
    # Validate image exists in registry
    echo "🔍 Verifying image exists in registry..."
    if docker manifest inspect "${FULL_IMAGE_NAME}" >/dev/null 2>&1; then
        echo "✅ Image found in registry"
    else
        echo "⚠️  Warning: Could not verify image in registry"
        echo "   Make sure you've pushed the image: docker push ${FULL_IMAGE_NAME}"
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Deployment cancelled."
            exit 1
        fi
    fi
    
    # Create the container instance with detailed error output
    echo "🚀 Executing container instance creation..."
    CONTAINER_RESULT=$(oci container-instances container-instance create \
        --compartment-id "${OCI_COMPARTMENT_ID}" \
        --availability-domain "${OCI_AVAILABILITY_DOMAIN}" \
        --display-name "csv-processor-$(date +%Y%m%d-%H%M%S)" \
        --shape "CI.Standard.E4.Flex" \
        --shape-config '{"memoryInGBs": 1, "ocpus": 1}' \
        --container-restart-policy "NEVER" \
        --image-pull-secrets "[{
            \"registryEndpoint\": \"${REGISTRY_URL}\",
            \"secretType\": \"BASIC\",
            \"username\": \"YXg5cm9vaWwwYm44L1Nob2xvZG5pY2tAY29uZXh1c3NnLmNvbQ==\",
            \"password\": \"NH16S1tlZUg+bXBCLUp9NFIzW3s=\"
        }]" \
        --vnics "[{
            \"subnetId\": \"${OCI_SUBNET_ID}\",
            \"assignPublicIp\": false,
            \"displayName\": \"csv-processor-vnic\"
        }]" \
        --containers "[{
            \"displayName\": \"csv-processor\",
            \"imageUrl\": \"${FULL_IMAGE_NAME}\",
            \"command\": [\"python\", \"download_csv_from_s3.py\", \"--s3-prefix\", \"input/\"],
            \"environmentVariables\": {
                \"ENVIRONMENT\": \"production\",
                \"PYTHONUNBUFFERED\": \"1\",
                \"TNS_ADMIN\": \"/app/wallet_demo\",
                \"VAULT_OCID\": \"${VAULT_OCID}\",
                \"OCI_LOG_OCID\": \"${OCI_LOG_OCID}\",
                \"OCI_COMPARTMENT_ID\": \"${OCI_COMPARTMENT_ID}\",
                \"AWS_ACCESS_KEY_SECRET_NAME\": \"${AWS_ACCESS_KEY_SECRET_NAME}\",
                \"AWS_SECRET_ACCESS_KEY_SECRET_NAME\": \"${AWS_SECRET_ACCESS_KEY_SECRET_NAME}\",
                \"DB_PASSWORD_SECRET_NAME\": \"${DB_PASSWORD_SECRET_NAME}\",
                \"AWS_DEFAULT_REGION\": \"${AWS_DEFAULT_REGION:-us-east-1}\",
                \"S3_BUCKET\": \"${S3_BUCKET:-cnxtestbucket}\",
                \"S3_PREFIX\": \"${S3_PREFIX:-input/}\",
                \"S3_REGION\": \"${S3_REGION:-us-east-1}\",
                \"DB_USER\": \"${DB_USER:-OAX_USER}\",
                \"DB_DSN\": \"${DB_DSN:-oax5007253621_low}\"
            },
            \"resourceConfig\": {
                \"memoryLimitInGBs\": 1,
                \"vcpusLimit\": 1
            }
        }]" \
        --wait-for-state SUCCEEDED 2>&1)
    
    # Check the result
    if [[ $? -eq 0 ]]; then
        echo "✅ Container instance creation initiated successfully!"
        
        # Extract container instance ID
        INSTANCE_ID=$(echo "$CONTAINER_RESULT" | jq -r '.data.id' 2>/dev/null || echo "")
        
        if [[ -n "$INSTANCE_ID" ]] && [[ "$INSTANCE_ID" != "null" ]]; then
            echo "📋 Container Instance ID: $INSTANCE_ID"
            echo ""
            echo "🔍 Checking container instance status..."
            oci container-instances container-instance get --container-instance-id "$INSTANCE_ID"
            echo ""
            echo "📊 To monitor the container:"
            echo "  oci container-instances container-instance get --container-instance-id $INSTANCE_ID"
            echo "  oci logging-search search-logs --time-start $(date -u -d '10 minutes ago' '+%Y-%m-%dT%H:%M:%SZ') --time-end $(date -u '+%Y-%m-%dT%H:%M:%SZ')"
        fi
    else
        echo "❌ Container instance creation failed!"
        echo ""
        echo "🔍 Error details:"
        echo "$CONTAINER_RESULT"
        echo ""
        echo "🛠️  Troubleshooting steps:"
        echo "1. Check if the image exists and is accessible:"
        echo "   docker pull ${FULL_IMAGE_NAME}"
        echo ""
        echo "2. Verify your OCI permissions for Container Instances"
        echo ""
        echo "3. Check subnet configuration allows container instances"
        echo ""
        echo "4. Validate availability domain has capacity:"
        echo "   oci limits resource-availability get --compartment-id ${OCI_COMPARTMENT_ID} --service-name compute"
        echo ""
        echo "5. Try a different availability domain or subnet"
        exit 1
    fi
fi

# Step 6: Deploy to Kubernetes (optional)
read -p "Do you want to deploy to Kubernetes? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "☸️  Deploying to Kubernetes..."
    
    # Update image in deployment file
    sed -i.bak "s|image: csv-processor:latest|image: ${FULL_IMAGE_NAME}|g" k8s-deployment.yaml
    
    # Apply deployment
    kubectl apply -f k8s-deployment.yaml
    
    # Wait for deployment
    kubectl rollout status deployment/csv-processor
    
    echo "✅ Kubernetes deployment successful!"
    echo "📊 Check status with: kubectl get pods -l app=csv-processor"
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "Next steps:"
echo "1. Update secrets with your AWS and Oracle credentials"
echo "2. Monitor the application logs"
echo "3. Set up monitoring and alerting"
echo ""
echo "For Kubernetes:"
echo "  kubectl get pods -l app=csv-processor"
echo "  kubectl logs -l app=csv-processor -f"
echo ""
echo "For OCI Container Instances:"
echo "  oci container-instances container-instance list --compartment-id ${OCI_COMPARTMENT_ID}"