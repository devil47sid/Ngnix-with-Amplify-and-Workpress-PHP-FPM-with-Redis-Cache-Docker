#!/bin/bash

CHECKPOINT_FILE=".checkpoint"

install_docker_compose(){
  is_install_docker_compose=$(is_executed install_docker_compose)
  if [[ "$is_install_docker_compose" == "false" ]]; then
    echo -e "\n<======== Installing Docker Compose =========>\n"
    sudo apt update -y &&

    #install a few prerequisite packages which let apt use packages over HTTPS
    sudo apt install apt-transport-https ca-certificates curl software-properties-common &&

    #Then add the GPG key for the official Docker repository to the system
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - &&

    #Add the Docker repository to APT sources
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable" -y &&

    #update the package database with the Docker packages from the newly added repo
    sudo apt update -y &&

    #Install Docker
    sudo apt install docker-ce -y &&

    #install docker compose
    sudo curl -L "https://github.com/docker/compose/releases/download/1.26.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &&

    sudo chmod +x /usr/local/bin/docker-compose
    if [ $? -eq 0 ]; then
      checkpoint install_docker_compose
    fi
  else
    echo -e "\n<========== Skipping docker-compose installation. Please use reset for reinstallation ==========>\n"
  fi
}

crete_site_folders(){
  is_crete_site_folders=$(is_executed crete_site_folders)
  if [[ "$is_crete_site_folders" == "false" ]]; then
    echo -e "\n<======== Creating required folders =========>\n"
    #Create required folders
    mkdir -p logs/nginx &&
    mkdir -p wordpress &&
    mkdir -p mariadb &&
    mkdir -p redis
    if [ $? -eq 0 ]; then
      checkpoint crete_site_folders
    fi
  else
    echo -e "\n<======== Skipping required folders creation. Please use reset for reinstallation ========>\n"
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
    echo -e "\n<======== Skipping certbot installation. Please use reset for reinstallation. ========>\n"
  fi

}

setup_ssl_site(){
  echo -e "\n<======== Setting up SSL ========>\n"
  is_setup_ssl_site=$(is_executed setup_ssl_site)
  if [[ "$is_setup_ssl_site" == "false" ]]; then
    install_certbot "$1"
    #Generate certificates
    sudo certbot certonly --standalone --preferred-challenges http -d "$1" --post-hook "sudo docker exec -it nginx nginx -s reload" &&
    cp setup/docker-compose-ssl.yml docker-compose.yml &&
    cp setup/wordpress-ssl.conf configurations/nginx/conf.d/ &&
    sed -i 's/domain/'$1'/g' configurations/nginx/conf.d/wordpress-ssl.conf &&
    sed -i 's/domain/'$1'/g' configurations/nginx/default.d/ssl.conf
    if [ $? -eq 0 ]; then
      checkpoint setup_ssl_site
    fi
  else
    echo -e "\n<======== Skipping SSL Setup. Please use reset for reinstallation. ========>\n"
  fi
}

setup_site(){
  echo -e "\n<======== Setting up ========>\n"
  is_setup_site=$(is_executed setup_site)
  if [[ "$is_setup_site" == "false" ]]; then
    cp setup/docker-compose.yml docker-compose.yml &&
    cp setup/wordpress.conf configurations/nginx/conf.d/
    if [ $? -eq 0 ]; then
      checkpoint setup_site
    fi
  else
    echo -e "\n<======== Skipping Setup. Please use reset for reinstallation. ========>\n"
  fi
}

get_installation_details(){
  #Interactive Site Intalltion
  read -p 'Domain Name: ' -r domain_name

  read -p 'Is SSL setup required?(Y/n): ' -r is_ssl_setup_required

  read -p 'Ngnix Amplify Key: ' -r ngnix_amplify_key

  read -p 'Ngnix Amplify Image Name: ' -r ngnix_amplify_image_name

  read -p 'Wordpress Database Name: ' -r wordpress_db_name

  read -p 'Database Password: ' -r db_password

  if [ -z "$domain_name" ] || [ -z "$is_ssl_setup_required" ] || [ -z "$ngnix_amplify_image_name" ] || [ -z "$ngnix_amplify_key" ] || [ -z "$wordpress_db_name" ] || [ -z "$db_password" ]
  then
    echo 'Inputs cannot be blank please try again!'
    exit 0
  fi
}

generate_env_file(){
  cat <<EOF >.env
DB_ROOT_PASSWORD=$db_password
DB_NAME=$wordpress_db_name
AMPLIFY_IMAGENAME=$ngnix_amplify_image_name
AMPLIFY_API_KEY=$ngnix_amplify_key
WORDPRESS_DB_USER=root
EOF
cp .env .env.$(date "+%Y.%m.%d-%H.%M.%S")
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
  if [[ "$1" == "Y" ]]; then
    #Creating checkpoint file
    touch $CHECKPOINT_FILE

    #Getting Intalltion Details
    get_installation_details

    #Generate .env file
    generate_env_file
  fi

  echo -e "\n<======== Starting Site installation ========>\n"

  #Installing Docker Compose
  install_docker_compose

  #Create Required folders
  crete_site_folders

  #Configuration Setup
  if [[ "$is_ssl_setup_required" == "Y" ]]; then
    setup_ssl_site $domain_name
  else
    setup_site
  fi

  #Start docker-compose
  sudo docker-compose up -d

  echo "Installtion is completed successfully!"
}

reset(){
  rm -rf $CHECKPOINT_FILE
  echo "Reset completed"
}

cat << "EOF"
_________.__  __           .___        __         .__  .__          __  .__
/   _____/|__|/  |_  ____   |   | _____/  |______  |  | |  | _____ _/  |_|__| ____   ____
\_____  \ |  \   __\/ __ \  |   |/    \   __\__  \ |  | |  | \__  \\   __\  |/  _ \ /    \
/        \|  ||  | \  ___/  |   |   |  \  |  / __ \|  |_|  |__/ __ \|  | |  (  <_> )   |  \
/_______  /|__||__|  \___  > |___|___|  /__| (____  /____/____(____  /__| |__|\____/|___|  /
      \/               \/           \/          \/               \/                    \/
EOF
echo -e "\nBy Siddharth Mishra | cloudtechbuilders.com"
cat << "EOF"
+-+-+-+ +-+-+ +-+-+-+
|$|i|d| |i|$| |d|i|$|
+-+-+-+ +-+-+ +-+-+-+
EOF

echo -e "\nPlease choose options: "
echo "1: Install New Site"
echo "2: Continue Previous Installtion"
echo "3: Reset"
while :
do
  read -p 'Enter: ' -r INPUT_STRING
  case $INPUT_STRING in
	1)
		install "Y"
    break;
		;;
  2)
  	install
    break;
  	;;
	3)
	  reset
		break
		;;
	*)
		echo "Sorry, You have choosed wrong option. Please try again"
    exit 0
		;;
  esac
done
