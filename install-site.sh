#!/bin/bash
sudo apt update -y

#install a few prerequisite packages which let apt use packages over HTTPS
sudo apt install apt-transport-https ca-certificates curl software-properties-common

#Then add the GPG key for the official Docker repository to the system
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Add the Docker repository to APT sources
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y

#update the package database with the Docker packages from the newly added repo
sudo apt update -y

#Install Docker
sudo apt install docker-ce -y

#install docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.23.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

#Create required folders
mkdir -p logs/nginx
mkdir -p wordpress
mkdir -p mariadb
mkdir -p redis

#Start docker-compose
sudo docker-compose up -d
