# AWS Deployment Script using AWS CLI
Write-Host "🚀 Deploying Resume Builder to AWS using AWS CLI..." -ForegroundColor Green

# Configuration
$BUCKET_NAME = "resume-uploader-bucker"
$REGION = "us-east-1"
$INSTANCE_TYPE = "t2.micro"
$AMI_ID = "ami-0c02fb55956c7d316"  # Amazon Linux 2
$SECURITY_GROUP_NAME = "resume-builder-sg"
$IAM_ROLE_NAME = "ResumeUploaderRole"

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

# Step 2: Create IAM Role
Write-Host "Step 2: Creating IAM role..." -ForegroundColor Cyan
$trustPolicy = '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}'

$trustPolicy | Out-File -FilePath "trust-policy.json" -Encoding UTF8
aws iam create-role --role-name $IAM_ROLE_NAME --assume-role-policy-document file://trust-policy.json
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ IAM role created: $IAM_ROLE_NAME" -ForegroundColor Green
} else {
    Write-Host "⚠️  IAM role may already exist, continuing..." -ForegroundColor Yellow
}

# Step 3: Attach S3 policy to role
Write-Host "Step 3: Attaching S3 policy to IAM role..." -ForegroundColor Cyan
$s3Policy = '{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:GetObject",
                "s3:PutObject",
                "s3:DeleteObject",
                "s3:ListBucket"
            ],
            "Resource": [
                "arn:aws:s3:::' + $BUCKET_NAME + '",
                "arn:aws:s3:::' + $BUCKET_NAME + '/*"
            ]
        }
    ]
}'

$s3Policy | Out-File -FilePath "s3-policy.json" -Encoding UTF8
aws iam put-role-policy --role-name $IAM_ROLE_NAME --policy-name "S3Access" --policy-document file://s3-policy.json

# Step 4: Create instance profile
Write-Host "Step 4: Creating instance profile..." -ForegroundColor Cyan
aws iam create-instance-profile --instance-profile-name "$IAM_ROLE_NAME-profile"
aws iam add-role-to-instance-profile --instance-profile-name "$IAM_ROLE_NAME-profile" --role-name $IAM_ROLE_NAME

# Step 5: Create security group
Write-Host "Step 5: Creating security group..." -ForegroundColor Cyan
aws ec2 create-security-group --group-name $SECURITY_GROUP_NAME --description "Security group for Resume Builder Flask app" --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 22 --cidr 0.0.0.0/0 --region $REGION
aws ec2 authorize-security-group-ingress --group-name $SECURITY_GROUP_NAME --protocol tcp --port 5000 --cidr 0.0.0.0/0 --region $REGION

# Step 6: Launch EC2 instance
Write-Host "Step 6: Launching EC2 instance..." -ForegroundColor Cyan
$userData = @"
#!/bin/bash
yum update -y
yum install -y python3 python3-pip git
mkdir -p /opt/resume-builder
cd /opt/resume-builder
pip3 install Flask boto3
export S3_BUCKET=$BUCKET_NAME
export AWS_REGION=$REGION
python3 -c "
from flask import Flask, request, render_template, redirect, url_for
import boto3
import os
from werkzeug.utils import secure_filename
from datetime import datetime

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'

S3_BUCKET = os.environ.get('S3_BUCKET', '$BUCKET_NAME')
AWS_REGION = os.environ.get('AWS_REGION', '$REGION')
s3 = boto3.client('s3', region_name=AWS_REGION)

ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    try:
        response = s3.list_objects_v2(Bucket=S3_BUCKET)
        files = []
        if 'Contents' in response:
            for obj in response['Contents']:
                files.append({
                    'key': obj['Key'],
                    'size': obj['Size'],
                    'last_modified': obj['LastModified'],
                    'size_mb': round(obj['Size'] / (1024 * 1024), 2)
                })
        return render_template('index.html', files=files)
    except Exception as e:
        return f'Error: {str(e)}'

@app.route('/upload', methods=['POST'])
def upload_file():
    try:
        if 'resume' not in request.files:
            return 'No file selected'
        
        file = request.files['resume']
        if file.filename == '':
            return 'No file selected'
        
        if file and file.filename and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            s3_key = f'resumes/{timestamp}_{filename}'
            s3.upload_fileobj(file, S3_BUCKET, s3_key)
            return f'Resume \"{filename}\" uploaded successfully!'
        else:
            return 'Invalid file type. Please upload PDF, DOC, or DOCX files.'
    except Exception as e:
        return f'Upload failed: {str(e)}'

@app.route('/download/<path:filename>')
def download_file(filename):
    try:
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': filename},
            ExpiresIn=3600
        )
        return redirect(url)
    except Exception as e:
        return f'Download failed: {str(e)}'

@app.route('/health')
def health_check():
    return {'status': 'healthy', 'bucket': S3_BUCKET}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
"

# Create simple HTML template
mkdir -p templates
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Resume Uploader</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
</head>
<body class="bg-light">
    <div class="container py-5">
        <h1 class="text-center mb-4">Resume Uploader</h1>
        
        <div class="card mb-4">
            <div class="card-header">Upload Resume</div>
            <div class="card-body">
                <form action="/upload" method="post" enctype="multipart/form-data">
                    <input type="file" name="resume" class="form-control mb-3" accept=".pdf,.doc,.docx" required>
                    <button type="submit" class="btn btn-primary">Upload Resume</button>
                </form>
            </div>
        </div>
        
        <div class="card">
            <div class="card-header">Uploaded Resumes</div>
            <div class="card-body">
                <ul class="list-group">
                    {% for file in files %}
                    <li class="list-group-item d-flex justify-content-between align-items-center">
                        {{ file.key.split('/')[-1] }}
                        <a href="{{ url_for('download_file', filename=file.key) }}" class="btn btn-sm btn-outline-primary">Download</a>
                    </li>
                    {% endfor %}
                </ul>
            </div>
        </div>
    </div>
</body>
</html>
EOF

# Start Flask app
python3 app.py
"@

$userData | Out-File -FilePath "user-data.sh" -Encoding UTF8

$instanceId = aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-groups $SECURITY_GROUP_NAME --iam-instance-profile Name="$IAM_ROLE_NAME-profile" --user-data file://user-data.sh --region $REGION --query 'Instances[0].InstanceId' --output text

if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ EC2 instance launched: $instanceId" -ForegroundColor Green
    
    # Wait for instance to be running
    Write-Host "Waiting for instance to be running..." -ForegroundColor Yellow
    aws ec2 wait instance-running --instance-ids $instanceId --region $REGION
    
    # Get public IP
    $publicIp = aws ec2 describe-instances --instance-ids $instanceId --region $REGION --query 'Reservations[0].Instances[0].PublicIpAddress' --output text
    
    Write-Host "✅ Deployment completed successfully!" -ForegroundColor Green
    Write-Host "🌐 Your Flask app is accessible at: http://$publicIp:5000" -ForegroundColor Cyan
    Write-Host "📦 S3 Bucket: $BUCKET_NAME" -ForegroundColor Cyan
    Write-Host "🖥️  EC2 Instance ID: $instanceId" -ForegroundColor Cyan
} else {
    Write-Host "❌ Failed to launch EC2 instance" -ForegroundColor Red
    exit 1
}

# Cleanup temporary files
Remove-Item -Path "trust-policy.json" -ErrorAction SilentlyContinue
Remove-Item -Path "s3-policy.json" -ErrorAction SilentlyContinue
Remove-Item -Path "user-data.sh" -ErrorAction SilentlyContinue 