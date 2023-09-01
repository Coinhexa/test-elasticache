#!/usr/bin/env bash
 
# Unofficial Bash Strict Mode
# http://redsymbol.net/articles/unofficial-bash-strict-mode/
# https://gist.github.com/vncsna/64825d5609c146e80de8b1fd623011ca
# https://stackoverflow.com/a/35800451/5371505
set -eEuox pipefail
IFS=$'\n\t'
# End of Unofficial Bash Strict Mode

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

# https://github.com/nodesource/distributions
yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y
yum install nodejs -y

# Download repo and install dependencies
echo "****************INSTALLING TEST-ELASTICACHE GITHUB REPO****************"

cd /home/ec2-user || exit
git clone https://github.com/Coinhexa/test-elasticache
chown -R ec2-user:ec2-user ./test-elasticache
cd /home/ec2-user/test-elasticache || exit
npm install
