#!/bin/bash

# PDF Processing Pipeline Deployment Script
# This script deploys the infrastructure to eu-west-1

set -e

REGION="eu-west-1"
ENVIRONMENT=$1
PROJECT_NAME="pdf-processing-pipeline"

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: ./deploy.sh <environment>"
    echo "Example: ./deploy.sh dev"
    exit 1
fi

echo "Deploying to environment: $ENVIRONMENT in region: $REGION"

# Get AWS Account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text --region $REGION)
echo "AWS Account ID: $ACCOUNT_ID"

# Create template bucket name
TEMPLATE_BUCKET="$PROJECT_NAME-templates-$ACCOUNT_ID-$REGION"
echo "Template bucket: $TEMPLATE_BUCKET"

# Create S3 bucket for templates if it doesn't exist
if ! aws s3api head-bucket --bucket $TEMPLATE_BUCKET --region $REGION 2>/dev/null; then
    echo "Creating template bucket: $TEMPLATE_BUCKET"
    aws s3api create-bucket \
        --bucket $TEMPLATE_BUCKET \
        --region $REGION \
        --create-bucket-configuration LocationConstraint=$REGION

    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket $TEMPLATE_BUCKET \
        --versioning-configuration Status=Enabled \
        --region $REGION
else
    echo "Template bucket already exists: $TEMPLATE_BUCKET"
fi

# Upload nested templates
echo "Uploading nested templates..."
aws s3 sync infrastructure/nested-stacks/ s3://$TEMPLATE_BUCKET/templates/nested-stacks/ --region $REGION

# Update parameter file with actual bucket name
sed "s/{ACCOUNT-ID}/$ACCOUNT_ID/g" infrastructure/parameters/$ENVIRONMENT.json > /tmp/$ENVIRONMENT-params.json

echo "Ready to deploy CloudFormation stack!"
echo "Template bucket: $TEMPLATE_BUCKET"
echo "Region: $REGION"
echo "Environment: $ENVIRONMENT"
