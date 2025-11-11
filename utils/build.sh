#!/bin/bash

# Build script for CSV Processor Docker container
set -e

echo "🔨 Building CSV Processor Docker Container..."

# Change to project root directory
cd "$(dirname "$0")/.."

# Build the Docker image for x64 architecture
docker build --platform linux/amd64 -t csv-processor:latest .

echo "✅ Docker image built successfully!"

# Tag for different registries (OCI compatible)
echo "🏷️  Tagging image for registry deployment..."

# Tag for local registry
docker tag csv-processor:latest localhost:5000/csv-processor:latest

# Tag for OCI registry (update with your registry URL)
# docker tag csv-processor:latest your-oci-registry.com/namespace/csv-processor:latest

echo "✅ Image tagged successfully!"

# Optional: Push to registry
read -p "Do you want to push to local registry? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "📤 Pushing to local registry..."
    docker push localhost:5000/csv-processor:latest
    echo "✅ Image pushed to local registry!"
fi

echo "🎉 Build process completed!"
echo ""
echo "To run the container:"
echo "  docker run --env-file .env csv-processor:latest --help"
echo ""
echo "To run with docker-compose:"
echo "  docker-compose up"