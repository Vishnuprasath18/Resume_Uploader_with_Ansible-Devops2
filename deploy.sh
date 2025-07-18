#!/bin/bash

# Resume Builder Deployment Script for WSL/Linux
# This script helps you deploy and manage your Resume Builder application

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${CYAN}$1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Check if action parameter is provided
ACTION=${1:-"setup"}

echo -e "${GREEN}🚀 Resume Builder Deployment Script${NC}"
echo "====================================="

# Check if AWS CLI is installed
print_status "Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    print_success "AWS CLI is installed"
else
    print_error "AWS CLI not found. Please install AWS CLI first."
    exit 1
fi

# Check if Ansible is available
print_status "Checking Ansible installation..."
if command -v ansible &> /dev/null; then
    print_success "Ansible is available"
else
    print_error "Ansible not found. Please install Ansible first."
    exit 1
fi

# Function to run setup
run_setup() {
    print_status "🔧 Setting up Resume Builder infrastructure..."
    
    # Check if AWS credentials are configured
    print_status "Checking AWS credentials..."
    if aws sts get-caller-identity &> /dev/null; then
        print_success "AWS credentials are configured"
    else
        print_error "AWS credentials not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_status "Running Ansible setup playbook..."
    ansible-playbook ansible/playbook-setup.yml -i ansible/inventory.ini
    
    if [ $? -eq 0 ]; then
        print_success "Setup completed successfully!"
        print_status "🌐 Your Flask app should be accessible at the URL shown above"
    else
        print_error "Setup failed. Check the error messages above."
    fi
}

# Function to run teardown
run_teardown() {
    print_status "🧹 Cleaning up Resume Builder infrastructure..."
    print_warning "This will delete all AWS resources created by this project."
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Running Ansible teardown playbook..."
        ansible-playbook ansible/playbook-teardown.yml -i ansible/inventory.ini
        
        if [ $? -eq 0 ]; then
            print_success "Cleanup completed successfully!"
        else
            print_error "Cleanup failed. Check the error messages above."
        fi
    else
        print_warning "Cleanup cancelled."
    fi
}

# Function to run test
run_test() {
    print_status "🧪 Testing Flask application locally..."
    
    # Check if Python dependencies are installed
    print_status "Installing Python dependencies..."
    pip install -r flask_app/requirements.txt
    
    # Set environment variables for local testing
    export S3_BUCKET="resume-uploader-bucker"
    export AWS_REGION="us-east-1"
    
    print_status "Starting Flask development server..."
    print_success "🌐 Access the app at: http://localhost:5000"
    print_warning "Press Ctrl+C to stop the server"
    
    python flask_app/app.py
}

# Main script logic
case $ACTION in
    "setup")
        run_setup
        ;;
    "teardown")
        run_teardown
        ;;
    "test")
        run_test
        ;;
    *)
        echo -e "${YELLOW}Usage: ./deploy.sh [setup|teardown|test]${NC}"
        echo ""
        echo "Actions:"
        echo "  setup     - Deploy the application to AWS"
        echo "  teardown  - Remove all AWS resources"
        echo "  test      - Run the Flask app locally for testing"
        ;;
esac 