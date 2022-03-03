rem # Build a container image and export to local file (for local testing).
rem # Run it from the host machine (outside the docker).
rem # Double click to run.
echo off

set ECR_REGION=ap-northeast-1
set ECR_REGISTRY="aws_account_id.dkr.ecr.%ECR_REGION%.amazonaws.com"
set ECR_REPOSITORY="test"
echo "ECR_REGION : %ECR_REGION%"
echo "ECR_REGISTRY : %ECR_REGISTRY%"
echo "ECR_REPOSITORY : %ECR_REPOSITORY%"

docker run --name export-image-amd64 -v %~dp0:/workspace gcr.io/kaniko-project/executor:latest --context dir:///workspace/ --dockerfile /workspace/build/Dockerfile.amd64 --destination %ECR_REGISTRY%/%ECR_REPOSITORY%:test --tarPath ./bin/image-amd64.tar --no-push
for /f "usebackq delims=" %%A in (`docker ps -aqf "name=export-image-amd64"`) do set CONTAINER_ID_AMD=%%A
docker rm -f %CONTAINER_ID_AMD%

docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
docker run --name export-image-arm64 -v %~dp0:/workspace gcr.io/kaniko-project/executor:latest --context dir:///workspace/ --dockerfile /workspace/build/Dockerfile.arm64 --destination %ECR_REGISTRY%/%ECR_REPOSITORY%:test --tarPath ./bin/image-arm64.tar --no-push
for /f "usebackq delims=" %%A in (`docker ps -aqf "name=export-image-arm64"`) do set CONTAINER_ID_ARM=%%A
docker rm -f %CONTAINER_ID_ARM%

echo "Completed the export process.

pause