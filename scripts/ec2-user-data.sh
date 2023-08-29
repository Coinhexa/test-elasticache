#!/bin/sh

# Update all packages
echo "****************UPDATING PACKAGES****************"

yum update -y

# Install redis with support for SSL
echo "****************INSTALLING REDIS****************"

yum install -y openssl-devel gcc
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable || exit
make distclean
make redis-cli BUILD_TLS=yes
install -m 755 src/redis-cli /usr/local/bin/

# Install node.js 16x
echo "****************INSTALLING NODE.JS****************"

curl -sL https://rpm.nodesource.com/setup_16.x | bash -
yum install -y nodejs git

# Install aws cli
echo "****************INSTALLING AWS CLI****************"

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
./aws/install

# Install docker

echo "****************INSTALLING DOCKER******************************"

yum install docker -y

echo "******************************CHANGING DOCKER PERMISSIONS******************************"

usermod -a -G docker ec2-user
id ec2-user
newgrp docker

echo "******************************ENABLING DOCKER SERVICE******************************"

systemctl enable docker.service
systemctl start docker.service

# Download repo and install dependencies
echo "****************INSTALLING TEST-ELASTICACHE GITHUB REPO****************"

cd /home/ec2-user || exit
git clone https://github.com/Coinhexa/test-elasticache
chown -R ec2-user:ec2-user ./test-elasticache
cd /home/ec2-user/test-elasticache || exit
npm install
