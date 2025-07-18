from flask import Flask, request, render_template, redirect, url_for, flash, jsonify
import boto3
import os
from werkzeug.utils import secure_filename
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)
app.secret_key = 'your-secret-key-here'  # Change this in production

# AWS Configuration
S3_BUCKET = os.environ.get('S3_BUCKET', 'resume-uploader-bucker')
AWS_REGION = os.environ.get('AWS_REGION', 'us-east-1')

# Initialize S3 client
s3 = boto3.client('s3', region_name=AWS_REGION)

# Allowed file extensions
ALLOWED_EXTENSIONS = {'pdf', 'doc', 'docx'}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/')
def index():
    """Main page - shows upload form and list of resumes"""
    try:
        # List all objects in S3 bucket
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
        logger.error(f"Error listing files: {e}")
        flash(f"Error loading resumes: {str(e)}", 'error')
        return render_template('index.html', files=[])

@app.route('/upload', methods=['POST'])
def upload_file():
    """Handle file upload to S3"""
    try:
        if 'resume' not in request.files:
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        file = request.files['resume']
        
        if file.filename == '':
            flash('No file selected', 'error')
            return redirect(url_for('index'))
        
        if file and file.filename and allowed_file(file.filename):
            # Secure the filename and add timestamp
            filename = secure_filename(file.filename)
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            s3_key = f"resumes/{timestamp}_{filename}"
            
            # Upload to S3
            s3.upload_fileobj(file, S3_BUCKET, s3_key)
            
            flash(f'Resume "{filename}" uploaded successfully!', 'success')
            logger.info(f"File uploaded: {s3_key}")
        else:
            flash('Invalid file type. Please upload PDF, DOC, or DOCX files.', 'error')
        
        return redirect(url_for('index'))
    
    except Exception as e:
        logger.error(f"Upload error: {e}")
        flash(f'Upload failed: {str(e)}', 'error')
        return redirect(url_for('index'))

@app.route('/download/<path:filename>')
def download_file(filename):
    """Generate pre-signed URL for file download"""
    try:
        # Generate pre-signed URL (valid for 1 hour)
        url = s3.generate_presigned_url(
            'get_object',
            Params={'Bucket': S3_BUCKET, 'Key': filename},
            ExpiresIn=3600
        )
        return redirect(url)
    except Exception as e:
        logger.error(f"Download error: {e}")
        flash(f'Download failed: {str(e)}', 'error')
        return redirect(url_for('index'))

@app.route('/delete/<path:filename>')
def delete_file(filename):
    """Delete file from S3"""
    try:
        s3.delete_object(Bucket=S3_BUCKET, Key=filename)
        flash(f'Resume "{filename}" deleted successfully!', 'success')
        logger.info(f"File deleted: {filename}")
    except Exception as e:
        logger.error(f"Delete error: {e}")
        flash(f'Delete failed: {str(e)}', 'error')
    
    return redirect(url_for('index'))

@app.route('/health')
def health_check():
    """Health check endpoint"""
    return jsonify({'status': 'healthy', 'bucket': S3_BUCKET})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True) 
    