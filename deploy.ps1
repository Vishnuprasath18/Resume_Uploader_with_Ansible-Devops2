# Resume Builder Deployment Script
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("setup", "teardown", "test")]
    [string]$Action = "setup"
)

Write-Host "🚀 Resume Builder Deployment Script" -ForegroundColor Green

switch ($Action) {
    "setup" {
        Write-Host "🔧 Setting up Resume Builder infrastructure..." -ForegroundColor Cyan
        python -m ansible playbook ansible/playbook-setup.yml -i ansible/inventory.ini
        break
    }
    "teardown" {
        Write-Host "🧹 Cleaning up Resume Builder infrastructure..." -ForegroundColor Cyan
        python -m ansible playbook ansible/playbook-teardown.yml -i ansible/inventory.ini
        break
    }
    "test" {
        Write-Host "🧪 Testing Flask application locally..." -ForegroundColor Cyan
        pip install -r flask_app/requirements.txt
        $env:S3_BUCKET = "resume-uploader-bucker"
        $env:AWS_REGION = "us-east-1"
        Write-Host "🌐 Access the app at: http://localhost:5000" -ForegroundColor Green
        python flask_app/app.py
        break
    }
    default {
        Write-Host 'Usage: .\deploy.ps1 [-Action setup|teardown|test]' -ForegroundColor Yellow
        break
    }
}
