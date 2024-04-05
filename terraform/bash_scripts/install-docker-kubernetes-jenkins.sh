#!/bin/bash
# This script is intended to install and configure Jenkins on Ubuntu 18.04

# Set the hostname of the machine to 'jenkins'
sudo hostnamectl set-hostname jenkins

# Update the installed packages and package cache on your instance.
sudo apt-get update && sudo apt-get upgrade -y

# Install necessary packages for Docker, kubectl, Python, and text editors
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common \
python3 python3-pip nano vim -y

# Docker Installation Steps
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce -y

# Start and enable the Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the current user to the Docker group
sudo usermod -aG docker $USER

# Download and install the latest kubectl binary
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Upgrade pip to the latest version
python3 -m pip install --upgrade pip

# Install FastAPI, Uvicorn, and other Python packages
pip3 install fastapi uvicorn httpx 'databases[mysql]' sqlalchemy

# Azure CLI Installation Steps
sudo apt-get update
sudo apt-get install ca-certificates curl apt-transport-https lsb-release gnupg
sudo mkdir -p /etc/apt/keyrings
curl -sLS https://packages.microsoft.com/keys/microsoft.asc |
    gpg --dearmor |
    sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
AZ_DIST=$(lsb_release -cs)
echo "deb [arch=`dpkg --print-architecture` signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $AZ_DIST main" |
    sudo tee /etc/apt/sources.list.d/azure-cli.list
sudo apt-get update
sudo apt-get install azure-cli

# Jenkins install
sudo apt install openjdk-11-jre -y
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo 'deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/' | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update && sudo apt-get install jenkins -y
sudo service jenkins restart