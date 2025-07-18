# 🚀 Resume Builder Setup Guide

## Prerequisites

### 1. AWS Account Setup
- Create an AWS account if you don't have one
- Set up AWS CLI: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
- Configure AWS credentials: `aws configure`

### 2. Install Required Software
```powershell
# Install Python dependencies
pip install ansible boto3 botocore

# Install AWS collections for Ansible
python -m ansible_galaxy collection install amazon.aws
```

## 🛠️ Quick Start

### Step 1: Configure AWS Credentials
```powershell
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key  
# Enter your default region (e.g., us-east-1)
# Enter your default output format (json)
```

### Step 2: Customize Configuration
Edit `ansible/group_vars/all.yml` to match your preferences:
- Change `bucket_name` to something unique
- Update `aws_region` if needed
- Modify `tags` with your information

### Step 3: Test Locally (Optional)
```powershell
.\deploy.ps1 -Action test
```
This will run the Flask app locally at http://localhost:5000

### Step 4: Deploy to AWS
```powershell
.\deploy.ps1 -Action setup
```

### Step 5: Access Your Application
- The deployment will show you the public IP address
- Access your app at: `http://<PUBLIC-IP>:5000`

### Step 6: Cleanup (When Done)
```powershell
.\deploy.ps1 -Action teardown
```

## 📁 Project Structure

```
resume-builder/
├── ansible/
│   ├── playbook-setup.yml      # Creates AWS infrastructure
│   ├── playbook-teardown.yml   # Removes AWS resources
│   ├── inventory.ini           # Ansible inventory
│   └── group_vars/
│       └── all.yml             # Configuration variables
├── flask_app/
│   ├── app.py                  # Main Flask application
│   ├── requirements.txt        # Python dependencies
│   └── templates/
│       └── index.html          # Web interface
├── deploy.ps1                  # Deployment script
├── README.md                   # Project overview
└── SETUP_GUIDE.md             # This file
```

## 🔧 Manual Deployment

If you prefer to run commands manually:

### Setup Infrastructure
```powershell
python -m ansible playbook ansible/playbook-setup.yml -i ansible/inventory.ini
```

### Cleanup Infrastructure
```powershell
python -m ansible playbook ansible/playbook-teardown.yml -i ansible/inventory.ini
```

## 🐛 Troubleshooting

### Common Issues:

1. **AWS Credentials Not Configured**
   ```powershell
   aws configure
   ```

2. **Ansible Not Found**
   ```powershell
   pip install ansible
   ```

3. **Permission Denied Errors**
   - Ensure your AWS user has the necessary permissions
   - Check IAM policies for EC2 and S3 access

4. **EC2 Instance Not Starting**
   - Check security group settings
   - Verify AMI ID is correct for your region
   - Check AWS console for error messages

5. **Flask App Not Accessible**
   - Verify security group allows port 5000
   - Check EC2 instance is running
   - SSH into instance to check service status

## 💰 AWS Free Tier Limits

- **EC2**: 750 hours/month of t2.micro
- **S3**: 5GB storage, 20,000 GET requests/month
- **IAM**: Free (no charges)

## 🔒 Security Notes

- Uses IAM roles for secure access (no hardcoded credentials)
- S3 bucket with proper permissions
- EC2 security groups configured for web access
- Always run teardown to avoid unexpected charges

## 📞 Support

If you encounter issues:
1. Check AWS CloudWatch logs
2. SSH into EC2 instance for debugging
3. Review Ansible playbook output for errors
4. Check AWS console for resource status 