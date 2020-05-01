#!/bin/bash
#==============================================================================
#                           AWX INSTALLATION SCRIPT
#
# Author:   malcolmvs@gmail.com | https://malcolm.cloud
#
# Source/Credits: How To Install Ansible AWX on Ubuntu 18.04 Linux
# - https://computingforgeeks.com/how-to-install-ansible-awx-on-ubuntu-linux/
# - Requires Ubuntu 18.04 LTS 
#
#---- Version History ---------------------------------------------------------
# 2020-05-01    1.0     Initial Version
#==============================================================================
#--- Update Ubuntu system
echo "---> Updating Ubuntu system"
sudo apt update


#==============================================================================
# Install Ansible on Ubuntu
#==============================================================================
#--- Install Ansible
echo "---> Installing Ansible"
echo "deb http://ppa.launchpad.net/ansible/ansible/ubuntu bionic main" | sudo tee /etc/apt/sources.list.d/ansible.list
sudo apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 93C4A3FD7BB9C367
sudo apt update
sudo apt install -y ansible

#--- Verify Ansible Installation
echo "---> Verifying Ansible installation"
ansible --version


#==============================================================================
# Install Docker Continer Engine
#==============================================================================
#--- Install basic dependencies
echo "---> Installing basic docker dependencies"
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common

#--- Import Docker repository GPG key
echo "---> Importing Docker repository GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#--- Add Docker CE repository to Ubuntu
echo "---> Adding Docker CE repository to Ubuntu"
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#--- Install Docker CE
echo "---> Installing Docker CE"
sudo apt update
sudo apt -y install docker-ce docker-ce-cli containerd.io

#--- Add your user account to docker group
echo "---> Add your user account to docker group"
sudo usermod -aG docker $USER
#newgrp docker

#--- Verify Docker version
echo "---> Verifying Docker version"
docker version


#==============================================================================
# Install Docker Compose
#==============================================================================
#--- Download the latest Compose
echo "---> Downloading the latest Compose"
curl -s https://api.github.com/repos/docker/compose/releases/latest | grep browser_download_url | grep docker-compose-Linux-x86_64 | cut -d '"' -f 4 | wget -qi -

#--- Make the binary file executable
echo "---> Making the binary file executable"
chmod +x docker-compose-Linux-x86_64

#--- Move the file to your PATH
echo "---> Moving the file to your PATH"
sudo mv docker-compose-Linux-x86_64 /usr/local/bin/docker-compose

#--- Confirm Docker Compose version
echo "---> Confirming Docker Compose version"
docker-compose version


#==============================================================================
# Install Node and NPM
#==============================================================================
echo "---> Installing Node and NPM"
sudo apt install -y nodejs npm
sudo npm install npm --global


#==============================================================================
# Install Ansible AWX
#==============================================================================
#--- Install docker-py python module
echo "---> Install docker-py python module"
sudo apt -y install python-pip git pwgen vim
sudo pip install requests==2.14.2

#--- Install docker-compose module which matches your Docker Compose version
echo "---> Installing docker-compose module which matches your Docker Compose version"
DOCKERVER=`docker-compose version | grep "docker-compose version" | cut -d, -f1 | cut -d" " -f3` 
sudo pip install docker-compose==$DOCKERVER

#--- Clone AWX source code from GitHub
echo "---> Cloning AWX source code from GitHub"
mkdir /awx
cd ~
git clone --depth 50 https://github.com/ansible/awx.git

#--- Backup inventory file
echo "---> Backup inventory file"
cd awx/installer/
mv inventory inventory.bak

#--- Generate Admin password and AWX secret key
echo "---> Generating Admin password and AWX secret key"
AWXKEY=`pwgen -N 1 -s 30`
AWXADMINPWD=`pwgen -N 1 -s 30`

#--- Create inventory file
echo "---> Creating inventory file"
touch inventory
echo "localhost ansible_connection=local ansible_python_interpreter=\"/usr/bin/env python2\"" >> inventory
echo "[all:vars]" >> inventory
echo "dockerhub_base=ansible" >> inventory
echo "awx_task_hostname=awx" >> inventory
echo "awx_web_hostname=awxweb" >> inventory
echo "postgres_data_dir=/awx/pgdocker" >> inventory
echo "host_port=80" >> inventory
echo "host_port_ssl=443" >> inventory
echo "docker_compose_dir=/awx/awxcompose" >> inventory
echo "pg_username=awx" >> inventory
echo "pg_password=awxpass" >> inventory
echo "pg_database=awx" >> inventory
echo "pg_port=5432" >> inventory
echo "rabbitmq_password=awxpass" >> inventory
echo "rabbitmq_erlang_cookie=cookiemonster" >> inventory
echo "admin_user=admin" >> inventory
echo "admin_password=$AWXADMINPWD" >> inventory
echo "create_preload_data=True" >> inventory
echo "secret_key=$AWXKEY" >> inventory

#--- Execute Playbook
echo "---> Executing Playbook, here we go!"
ansible-playbook -i inventory install.yml

#--- List running containers
echo "---> Listing running containers"
docker ps


#==============================================================================
# Done - display login creds
#==============================================================================
PUBLICIPv4=`curl http://169.254.169.254/latest/meta-data/public-ipv4`
echo ""
echo "------------------------------------------------------------------------"
echo "AWX installation complete!"
echo ""
echo "URL:      http://$PUBLICIPv4"
echo "Username: admin"
echo "Password: $AWXADMINPWD"
echo ""
echo "------------------------------------------------------------------------"
echo ""
