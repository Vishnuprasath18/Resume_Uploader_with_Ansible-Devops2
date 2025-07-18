# Final AWS Deployment Script for Resume Builder
Write-Host "🚀 Deploying Resume Builder to AWS..." -ForegroundColor Green

# Configuration
$BUCKET_NAME = "resume-uploader-bucker"
$REGION = "us-east-1"
$INSTANCE_TYPE = "t2.micro"
$AMI_ID = "ami-0c02fb55956c7d316"  # Amazon Linux 2
$SECURITY_GROUP_NAME = "resume-builder-sg"

# Check AWS credentials
Write-Host "Checking AWS credentials..." -ForegroundColor Yellow
try {
    $awsIdentity = aws sts get-caller-identity
    Write-Host "✅ AWS credentials verified" -ForegroundColor Green
} catch {
    Write-Host "❌ AWS credentials not configured. Please run 'aws configure' first." -ForegroundColor Red
    exit 1
}

# Step 1: Create S3 Bucket
Write-Host "Step 1: Creating S3 bucket..." -ForegroundColor Cyan
aws s3 mb s3://$BUCKET_NAME --region $REGION
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ S3 bucket created: $BUCKET_NAME" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to create S3 bucket" -ForegroundColor Red
    exit 1
}

# Step 2: Create security group
Write-Host "Step 2: Creating security group..." -ForegroundColor Cyan
aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for Resume Builder Flask app" --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region $REGION

# Step 3: Launch EC2 instance
Write-Host "Step 3: Launching EC2 instance..." -ForegroundColor Cyan
$instanceId = aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-groups $SECURITY_GROUP_NAME --region $REGION --query 'Instances[0].InstanceId' --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Write-Host "Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region $REGION
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "🌐 Your EC2 instance is running at: $publicIp" -ForegroundColor Cyan
    Write-Host "📦 S3 Bucket: $BUCKET_NAME" -ForegroundColor Cyan
    Write-Host "🖥️  EC2 Instance ID: $instanceId" -ForegroundColor Cyan
    Write-Host "" -ForegroundColor White
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. SSH into the instance: ssh ec2-user@$publicIp" -ForegroundColor White
    Write-Host "2. Install Python and Flask" -ForegroundColor White
    Write-Host "3. Copy your Flask app to the instance" -ForegroundColor White
    Write-Host "4. Run the Flask app: python3 app.py" -ForegroundColor White
} else {
    Write-Host "❌ Failed to launch EC2 instance" -ForegroundColor Red
    exit 1
} 