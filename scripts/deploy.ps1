param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("s3", "dynamodb", "lambda", "all")]
    [string]$Component,
    
    [string]$Environment = "dev",
    [string]$Region = "eu-west-1"
)

function Deploy-Component {
    param($ComponentName, $StackName, $TemplateFile, $ExtraParams = @())
    
    Write-Host "Deploying $ComponentName..." -ForegroundColor Green
    
    $params = @(
        "Environment=$Environment",
        "Region=$Region"
    ) + $ExtraParams
    
    aws cloudformation deploy `
        --template-file $TemplateFile `
        --stack-name $StackName `
        --parameter-overrides $params `
        --capabilities CAPABILITY_IAM `
        --region $Region
}

switch ($Component) {
    "s3" { 
        Deploy-Component "S3" "pdf-s3-$Environment" "infrastructure/s3.yaml"
    }
    "dynamodb" { 
        Deploy-Component "DynamoDB" "pdf-dynamodb-$Environment" "infrastructure/dynamodb.yaml"
    }
    "lambda" { 
        Deploy-Component "Lambda" "pdf-lambda-$Environment" "infrastructure/lambda.yaml"
    }
    "all" {
        Deploy-Component "S3" "pdf-s3-$Environment" "infrastructure/s3.yaml"
        Deploy-Component "DynamoDB" "pdf-dynamodb-$Environment" "infrastructure/dynamodb.yaml"
        Deploy-Component "Lambda" "pdf-lambda-$Environment" "infrastructure/lambda.yaml"
    }
}

Write-Host "Deployment complete!" -ForegroundColor Green