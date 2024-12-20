# backup.sh
#!/bin/sh


# Install necessary packages
yum install zip unzip -y

# Determine the architecture of the machine
ARCH=$(uname -m)

# Download and install the appropriate AWS CLI version based on the architecture
if [ "$ARCH" = "x86_64" ]; then
    echo "Detected architecture: x86_64"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
elif [ "$ARCH" = "aarch64" ]; then
    echo "Detected architecture: aarch64"
    curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

# Unzip the downloaded package
unzip awscliv2.zip

# Install the AWS CLI
./aws/install

#Create a zip file for jenkins home directory
zip -r /backup/jenkins_home_backup.zip /var/jenkins_home

#Upload the zip file to AWS S3 bucket for backup
aws s3 cp /backup/jenkins_home_backup.zip s3://${backup_bucket_name}/$(date '+%Y-%m-%d')/jenkins_home_backup.zip
