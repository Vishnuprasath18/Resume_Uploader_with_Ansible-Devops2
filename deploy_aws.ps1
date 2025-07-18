Write-Host "🚀 Deploying Resume Builder to AWS..." -ForegroundColor Green

$BUCKET_NAME = "resume-uploader-bucker"
$REGION = "us-east-1"
$INSTANCE_TYPE = "t2.micro"
$AMI_ID = "ami-0c02fb55956c7d316"
$SECURITY_GROUP_NAME = "resume-builder-sg"

Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
$awsIdentity = aws sts get-caller-identity
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ AWS credentials not configured" -ForegroundColor Red
    exit 1
} else {
    Write-Host "✅ AWS credentials verified" -ForegroundColor Green
}

Write-Host "Creating S3 bucket..." -ForegroundColor Cyan
aws s3 mb s3://$BUCKET_NAME --region $REGION

Write-Host "Creating security group..." -ForegroundColor Cyan
aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for Resume Builder" --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region $REGION

Write-Host "Launching EC2 instance..." -ForegroundColor Cyan
$instanceId = aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-groups $SECURITY_GROUP_NAME --region $REGION --query 'Instances[0].InstanceId' --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green

    Write-Host "Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region $REGION

    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text

    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "🌐 Your EC2 instance is running at: $publicIp" -ForegroundColor Cyan
    Write-Host "📦 S3 Bucket: $BUCKET_NAME" -ForegroundColor Cyan
    Write-Host "🖥️  EC2 Instance ID: $instanceId" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to launch EC2 instance" -ForegroundColor Red
}