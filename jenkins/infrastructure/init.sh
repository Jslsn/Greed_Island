#!/bin/bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sudo apt update
sudo apt install -y docker.io
docker run --name jenkins -p 8080:8080 -p 50000:50000 -d -v jenkins_home:/var/jenkins_home jenkins/jenkins:lts
docker exec -u 0 jenkins apt update
docker exec -u 0 jenkins apt install curl
docker exec -u 0 jenkins curl -sL https://deb.nodesource.com/setup_16.x -o nodeource_setup.sh
docker exec -u 0 jenkins bash nodeource_setup.sh
docker exec -u 0 jenkins apt install nodejs

