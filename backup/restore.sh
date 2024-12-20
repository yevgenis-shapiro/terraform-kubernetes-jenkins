# restore.sh
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

#Download the jenkins backup file
aws s3 cp s3://${backup_bucket_name}/${backup_restore_date}/jenkins_home_backup.zip /restore

#Unzip  the jenkins backup file in /restore directory
unzip  /restore/jenkins_home_backup.zip  -d /restore

#Update the permission so that jenkins master pod can access the files
chown -R 1000:1000 /restore/var

#Copy the files to Jenkins home directoy to restore the changes.
cp -avr /restore/var/jenkins_home/. /var/jenkins_home

# sleep 500;
