# PDF Processing Pipeline Deployment Script for PowerShell
# This script deploys the infrastructure to eu-west-1

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("dev", "staging", "prod")]
    [string]$Environment
)

$Region = "eu-west-1"
$ProjectName = "pdf-processing-pipeline"

Write-Host "Deploying to environment: $Environment in region: $Region" -ForegroundColor Green

# Get AWS Account ID
$AccountId = (aws sts get-caller-identity --query Account --output text --region $Region)
Write-Host "AWS Account ID: $AccountId" -ForegroundColor Yellow

# Create template bucket name
$TemplateBucket = "$ProjectName-templates-$AccountId-$Region"
Write-Host "Template bucket: $TemplateBucket" -ForegroundColor Yellow

# Check if template bucket exists
try {
    aws s3api head-bucket --bucket $TemplateBucket --region $Region 2>$null
    Write-Host "Template bucket already exists: $TemplateBucket" -ForegroundColor Green
} catch {
    Write-Host "Creating template bucket: $TemplateBucket" -ForegroundColor Yellow

    # Create bucket
    aws s3api create-bucket --bucket $TemplateBucket --region $Region --create-bucket-configuration LocationConstraint=$Region

    # Enable versioning
    aws s3api put-bucket-versioning --bucket $TemplateBucket --versioning-configuration Status=Enabled --region $Region

    Write-Host "Template bucket created successfully!" -ForegroundColor Green
}

# Upload nested templates
Write-Host "Uploading nested templates..." -ForegroundColor Yellow
aws s3 sync infrastructure/nested-stacks/ s3://$TemplateBucket/templates/nested-stacks/ --region $Region

# Update parameter file with actual bucket name
$ParamContent = Get-Content "infrastructure\parameters\$Environment.json" -Raw
$UpdatedParams = $ParamContent -replace "{ACCOUNT-ID}", $AccountId
$UpdatedParams | Out-File -FilePath "infrastructure\parameters\$Environment-updated.json" -Encoding UTF8

Write-Host "Ready to deploy CloudFormation stack!" -ForegroundColor Green
Write-Host "Template bucket: $TemplateBucket" -ForegroundColor Cyan
Write-Host "Region: $Region" -ForegroundColor Cyan
Write-Host "Environment: $Environment" -ForegroundColor Cyan
