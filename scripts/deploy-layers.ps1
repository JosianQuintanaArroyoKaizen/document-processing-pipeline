param(
    [string]$Environment = "dev",
    [string]$Region = "eu-west-1"
)

Write-Host "Building Lambda layers..." -ForegroundColor Green

# Build layers
Set-Location "layers"
.\build-pdf-layer.ps1
.\build-image-layer.ps1
Set-Location ".."

# Deploy layers infrastructure first
Write-Host "Deploying layers infrastructure..." -ForegroundColor Green
aws cloudformation deploy `
    --template-file infrastructure/layers.yaml `
    --stack-name pdf-layers-$Environment `
    --parameter-overrides Environment=$Environment `
    --region $Region

# Upload layer files to S3
$bucketName = "pdf-layers-$Environment-$(aws sts get-caller-identity --query Account --output text)-$Region"

Write-Host "Uploading layers to S3..." -ForegroundColor Green
aws s3 cp layers/build/pdf-layer.zip s3://$bucketName/pdf-layer.zip
aws s3 cp layers/build/image-layer.zip s3://$bucketName/image-layer.zip

# Update layer versions
Write-Host "Updating layer versions..." -ForegroundColor Green
aws cloudformation deploy `
    --template-file infrastructure/layers.yaml `
    --stack-name pdf-layers-$Environment `
    --parameter-overrides Environment=$Environment `
    --region $Region

# Deploy updated Lambda functions
Write-Host "Deploying updated Lambda functions..." -ForegroundColor Green
aws cloudformation deploy `
    --template-file infrastructure/lambda.yaml `
    --stack-name pdf-lambda-$Environment `
    --parameter-overrides Environment=$Environment Region=$Region `
    --capabilities CAPABILITY_IAM `
    --region $Region

Write-Host "Layer deployment complete!" -ForegroundColor Green