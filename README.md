graph TB
    subgraph "Local Development"
        A[Flask App Code] --> B[Ansible Playbooks]
        B --> C[Deploy Script]
    end
    
    subgraph "AWS Infrastructure"
        D[S3 Bucket<br/>resume-uploader-bucker] --> E[File Storage]
        F[IAM Role<br/>ResumeUploaderRole] --> G[Security Permissions]
        H[Security Group<br/>resume-builder-sg] --> I[Network Rules]
        J[EC2 Instance<br/>t2.micro] --> K[Flask Application]
    end
    
    subgraph "User Interaction"
        L[User Browser] --> M[Upload Resume]
        M --> N[Download Resume]
        M --> O[Delete Resume]
    end
    
    C --> D
    C --> F
    C --> H
    C --> J
    
    K --> E
    K --> G
    K --> I
    
    L --> K
    N --> E
    O --> E
    
    style A fill:#e1f5fe
    style B fill:#f3e5f5
    style C fill:#fff3e0
    style D fill:#e8f5e8
    style F fill:#e8f5e8
    style H fill:#e8f5e8
    style J fill:#e8f5e8
    style K fill:#fff3e0
# Resume Builder - AWS DevOps Automation Project

## 🚀 Project Overview
This project demonstrates DevOps automation using Ansible to deploy a Flask-based Resume Uploader application on AWS EC2 with S3 storage.

## 📋 Project Roadmap

### Phase 1: Project Setup & Pre-requisites ✅
- [x] AWS IAM Role Creation
- [x] S3 Bucket Creation  
- [x] Ansible Environment Setup

### Phase 2: Ansible Automation 🔄
- [ ] Write Ansible playbook to:
  - Launch EC2 instance with IAM Role
  - Install Python, Flask, Git
  - Clone the Flask app repo
  - Run the Flask app on startup

### Phase 3: Flask Resume Uploader App 🔄
- [ ] Create lightweight Flask app:
  - Upload resumes (PDFs)
  - Store to S3
  - List and download resumes

### Phase 4: Teardown Playbook (Cleanup) 🔄
- [ ] Ansible playbook to:
  - Terminate EC2
  - Delete bucket contents
  - Delete bucket

## 🏗️ Project Structure
```
resume-builder/
├── ansible/
│   ├── playbook-setup.yml         # Launch EC2, install dependencies, deploy app
│   ├── playbook-teardown.yml      # Cleanup resources
│   ├── inventory.ini              # Ansible inventory file
│   └── group_vars/
│       └── all.yml                # Variables (bucket name, region)
├── flask_app/
│   ├── app.py                     # Main Flask app
│   ├── requirements.txt           # Python dependencies
│   └── templates/
│       └── index.html             # Simple upload/list UI
├── README.md
└── .gitignore
```

## 🛠️ Prerequisites
- AWS Account with Free Tier access
- AWS CLI configured with access keys
- Ansible installed
- Python 3.x

## 🚀 Quick Start
1. Configure AWS credentials: `aws configure`
2. Update variables in `ansible/group_vars/all.yml`
3. Run setup: `ansible-playbook ansible/playbook-setup.yml`
4. Access the app at: `http://<EC2-PUBLIC-IP>:5000`
5. Cleanup: `ansible-playbook ansible/playbook-teardown.yml`

## 💰 AWS Free Tier Usage
- EC2: t2.micro (750 hours/month)
- S3: 5GB storage, 20,000 GET requests/month
- IAM: Free

## 🔒 Security Notes
- Uses IAM roles for secure access (no hardcoded credentials)
- S3 bucket with proper permissions
- EC2 security groups configured for web access 
