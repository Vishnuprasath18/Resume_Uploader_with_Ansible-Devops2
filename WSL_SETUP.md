# 🐧 WSL Setup Guide for Resume Builder

## Why WSL?

WSL (Windows Subsystem for Linux) provides a better environment for DevOps tools like Ansible, as it runs natively on Linux. This avoids many Windows-specific issues with Python, Ansible, and AWS CLI.

## 🚀 Quick Setup in WSL

### 1. Open WSL Terminal
```bash
# Open Windows Terminal and select Ubuntu/WSL
# Or run: wsl
```

### 2. Navigate to Your Project
```bash
# Navigate to your project directory
cd /mnt/c/Users/vishn/OneDrive/Documents/Devops\ projects/Resume\ Builder
```

### 3. Install Dependencies in WSL
```bash
# Update package list
sudo apt update

# Install Python and pip
sudo apt install -y python3 python3-pip

# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Install Ansible
pip3 install ansible boto3 botocore

# Install AWS collections for Ansible
ansible-galaxy collection install amazon.aws
```

### 4. Configure AWS Credentials
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your default region (us-east-1)
# Enter your default output format (json)
```

### 5. Test the Deployment Script
```bash
# Make script executable (if not already done)
chmod +x deploy.sh

# Test locally
./deploy.sh test

# Deploy to AWS
./deploy.sh setup

# Cleanup when done
./deploy.sh teardown
```

## 🔧 WSL-Specific Tips

### File Permissions
```bash
# If you get permission errors, fix file permissions
chmod +x deploy.sh
chmod +x ansible/playbook-setup.yml
chmod +x ansible/playbook-teardown.yml
```

### Path Issues
```bash
# If Python/Ansible not found, check your PATH
echo $PATH
which python3
which ansible

# Add to PATH if needed
export PATH=$PATH:~/.local/bin
```

### AWS CLI in WSL
```bash
# Verify AWS CLI works
aws --version
aws sts get-caller-identity
```

## 🐛 Common WSL Issues

### 1. **Line Ending Issues**
```bash
# Convert Windows line endings to Unix
dos2unix deploy.sh
dos2unix ansible/*.yml
```

### 2. **Permission Denied**
```bash
# Fix file permissions
chmod +x *.sh
chmod +x ansible/*.yml
```

### 3. **Python Path Issues**
```bash
# Use python3 explicitly
python3 -m pip install ansible
python3 -m ansible --version
```

### 4. **AWS Credentials Not Found**
```bash
# Check AWS credentials location
ls -la ~/.aws/
cat ~/.aws/credentials
```

## 🚀 Usage Examples

### Test Locally
```bash
./deploy.sh test
# Access at: http://localhost:5000
```

### Deploy to AWS
```bash
./deploy.sh setup
# Follow the output to get your EC2 public IP
```

### Cleanup
```bash
./deploy.sh teardown
# Confirms before deleting AWS resources
```

## 📁 Project Structure in WSL

```
/mnt/c/Users/vishn/OneDrive/Documents/Devops projects/Resume Builder/
├── deploy.sh                    # WSL deployment script
├── deploy.ps1                   # Windows PowerShell script
├── ansible/
│   ├── playbook-setup.yml
│   ├── playbook-teardown.yml
│   ├── inventory.ini
│   └── group_vars/
│       └── all.yml
├── flask_app/
│   ├── app.py
│   ├── requirements.txt
│   └── templates/
│       └── index.html
└── README.md
```

## 💡 Benefits of WSL

- ✅ **Better Python support** - Native Linux Python environment
- ✅ **Ansible compatibility** - Designed for Linux
- ✅ **AWS CLI reliability** - Better performance and compatibility
- ✅ **Git integration** - Native Linux Git commands
- ✅ **Package management** - Use apt for system packages

## 🔄 Switching Between Windows and WSL

### From Windows PowerShell:
```powershell
# Open WSL
wsl

# Navigate to project
cd /mnt/c/Users/vishn/OneDrive/Documents/Devops\ projects/Resume\ Builder
```

### From WSL:
```bash
# Access Windows files
ls /mnt/c/Users/vishn/OneDrive/Documents/Devops\ projects/Resume\ Builder/

# Run Windows commands
cmd.exe /c "dir"
```

## 🎯 Next Steps

1. **Open WSL terminal**
2. **Navigate to your project directory**
3. **Run: `./deploy.sh test`** to test locally
4. **Configure AWS credentials: `aws configure`**
5. **Deploy: `./deploy.sh setup`**

The WSL environment should provide a much smoother experience for your DevOps automation project! 