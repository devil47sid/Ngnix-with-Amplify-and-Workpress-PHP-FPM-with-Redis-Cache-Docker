#!/bin/bash

CHECKPOINT_FILE=".checkpoint"

install_docker_compose(){
  is_install_docker_compose=$(is_executed install_docker_compose)
  if [[ "$is_install_docker_compose" == "false" ]]; then
    echo "Installing Docker Compose ......."
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
    sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

    sudo chmod +x /usr/local/bin/docker-compose
    if [ $? -eq 0 ]; then
      checkpoint install_docker_compose
    fi
  else
    echo "Skipping docker-compose installation. Please use reset for reinstallation."
  fi
}

crete_site_folders(){
  is_crete_site_folders=$(is_executed crete_site_folders)
  if [[ "$is_crete_site_folders" == "false" ]]; then
    echo "Creating required folders ......."
    #Create required folders
    mkdir -p logs/nginx
    mkdir -p wordpress
    mkdir -p mariadb
    mkdir -p redis
    if [ $? -eq 0 ]; then
      checkpoint crete_site_folders
    fi
  else
    echo "Skipping required folders creation. Please use reset for reinstallation."
  fi
}

install_certbot(){
  is_install_certbot=$(is_executed install_certbot)
  if [[ "$is_install_certbot" == "false" ]]; then
    echo "Installing certbot ......."
    #Install certbot
    sudo apt-get install certbot -y
    if [ $? -eq 0 ]; then
      checkpoint install_certbot
    fi
  else
    echo "Skipping certbot installation. Please use reset for reinstallation."
  fi

}

setup_ssl_site(){
  echo "Setting up SSL ......."
  is_setup_ssl_site=$(is_executed setup_ssl_site)
  if [[ "$is_setup_ssl_site" == "false" ]]; then
    install_certbot "$1"
    #Generate certificates
    sudo certbot certonly --standalone --preferred-challenges http -d "$1"
    cp setup/docker-compose-ssl.yml docker-compose.yml
    cp setup/wordpress-ssl.conf configurations/nginx/conf.d/
    sed -i 's/domain/$1/g' configurations/nginx/conf.d/wordpress-ssl.conf
    sed -i 's/domain/$1/g' configurations/nginx/default.d/ssl.conf
    if [ $? -eq 0 ]; then
      checkpoint setup_ssl_site
    fi
  else
    echo "Skipping SSL Setup. Please use reset for reinstallation."
  fi
}

get_installation_details(){
  #Interactive Site Intalltion
  echo "Domain Name: "
  read domain_name

  echo "Is SSL setup required? (Y/n)"
  read is_ssl_setup_required

  #Get Ngnix Amplify Key
  echo "Ngnix Amplify Key: "
  read ngnix_amplify_key

  #Get Ngnix Amplify Image Name
  echo "Ngnix Amplify Image Name: "
  read ngnix_amplify_image_name

  #Get Wordpress database Name
  echo "Wordpress Database Name: "
  read wordpress_db_name

  #Get Database Password
  echo "Database Password: "
  read db_password

  if [ -z "$domain_name" ] || [ -z "$is_ssl_setup_required" ] || [ -z "$ngnix_amplify_image_name" ] || [ -z "$ngnix_amplify_key" ] || [ -z "$wordpress_db_name" ] || [ -z "$db_password" ]
  then
    echo 'Inputs cannot be blank please try again!'
    exit 0
  fi
}

checkpoint(){
  if [ -z "$1" ]
  then
    echo "No argument supplied"
  else
   echo -e "$1\n" >> $CHECKPOINT_FILE
  fi
}

is_executed(){
  if grep -q "$1" $CHECKPOINT_FILE; then
    echo true
  else
    echo false
  fi
}

install(){
  #Creating checkpoint file
  touch $CHECKPOINT_FILE

  #Getting Intalltion Details
  get_installation_details

  #Installing Docker Compose
  install_docker_compose

  #Create Required folders
  crete_site_folders

  if [[ "$is_ssl_setup_required" == "Y" ]]; then
    setup_ssl_site $domain_name
  else
    echo "No SSL"
  fi

}



#Start docker-compose
#sudo docker-compose up -d
