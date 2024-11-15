#!/bin/bash

# Exit on error
set -e

# Variables
REPO_URL="https://github.com/<username>/<repository>.git"
APP_DIR="/var/www/<application>"
BRANCH="main"  # Specify the branch to deploy
SERVICE_NAME="<service-name>"  # Optional: systemd service name

# Update system packages
echo "Updating system packages..."
sudo yum update -y

# Ensure Git is installed
echo "Checking if Git is installed..."
if ! command -v git &> /dev/null; then
    echo "Git not found, installing..."
    sudo yum install git -y
fi

# Clone or update repository
if [ ! -d "$APP_DIR" ]; then
    echo "Cloning repository into $APP_DIR..."
    sudo git clone -b $BRANCH $REPO_URL $APP_DIR
else
    echo "Updating existing repository in $APP_DIR..."
    cd $APP_DIR
    sudo git reset --hard  # Discard local changes
    sudo git pull origin $BRANCH  # Pull latest changes
fi

# Navigate to application directory
cd $APP_DIR

# Install application dependencies (modify as needed)
if [ -f "package.json" ]; then
    echo "Installing Node.js dependencies..."
    curl -fsSL https://rpm.nodesource.com/setup_18.x | sudo bash -
    sudo yum install -y nodejs
    npm install
elif [ -f "requirements.txt" ]; then
    echo "Installing Python dependencies..."
    sudo yum install -y python3 python3-pip
    pip3 install -r requirements.txt
fi

# Build or prepare application (if necessary)
if [ -f "Dockerfile" ]; then
    echo "Building and running Docker container..."
    sudo yum install -y docker
    sudo systemctl start docker
    sudo docker build -t myapp .
    sudo docker run -d -p 80:80 --name myapp-container myapp
elif [ -f "build.sh" ]; then
    echo "Running custom build script..."
    chmod +x build.sh
    ./build.sh
fi

# Restart application service (if applicable)
if [ -f "/etc/systemd/system/$SERVICE_NAME.service" ]; then
    echo "Restarting $SERVICE_NAME service..."
    sudo systemctl daemon-reload
    sudo systemctl restart $SERVICE_NAME
    sudo systemctl enable $SERVICE_NAME
else
    echo "No systemd service file found. Starting app manually..."
    # Example for Node.js or Python apps
    nohup npm start &  # Replace with your app's start command
fi

# Completion message
echo "Deployment complete!"
