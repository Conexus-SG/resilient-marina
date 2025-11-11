@echo off
REM Build script for CSV Processor Docker container (Windows)
setlocal enabledelayedexpansion

echo 🔨 Building CSV Processor Docker Container...

REM Change to project root directory
cd /d "%~dp0\.."

REM Build the Docker image for x64 architecture
docker build --platform linux/amd64 -t csv-processor:latest .
if !errorlevel! neq 0 (
    echo ❌ Docker build failed!
    exit /b 1
)

echo ✅ Docker image built successfully!

REM Tag for different registries (OCI compatible)
echo 🏷️  Tagging image for registry deployment...

REM Tag for local registry
docker tag csv-processor:latest localhost:5000/csv-processor:latest

REM Tag for OCI registry (update with your registry URL)
REM docker tag csv-processor:latest your-oci-registry.com/namespace/csv-processor:latest

echo ✅ Image tagged successfully!

REM Optional: Push to registry
set /p push="Do you want to push to local registry? (y/n): "
if /i "!push!"=="y" (
    echo 📤 Pushing to local registry...
    docker push localhost:5000/csv-processor:latest
    echo ✅ Image pushed to local registry!
)

echo 🎉 Build process completed!
echo.
echo To run the container:
echo   docker run --env-file .env csv-processor:latest --help
echo.
echo To run with docker-compose:
echo   docker-compose up