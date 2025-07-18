# Simple test script for Flask app
Write-Host "🧪 Testing Flask application locally..." -ForegroundColor Cyan

# Install Python dependencies
Write-Host "Installing Python dependencies..." -ForegroundColor Yellow
pip install -r flask_app/requirements.txt

# Set environment variables
$env:S3_BUCKET = "resume-uploader-bucker"
$env:AWS_REGION = "us-east-1"

Write-Host "Starting Flask development server..." -ForegroundColor Yellow
Write-Host "🌐 Access the app at: http://localhost:5000" -ForegroundColor Green
Write-Host "Press Ctrl+C to stop the server" -ForegroundColor Yellow

# Start Flask app
python flask_app/app.py 