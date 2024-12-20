#!/bin/bash

# Update and upgrade the system
sudo apt update && sudo apt upgrade -y

# check jq is installed or not
if ! command -v jq &> /dev/null; then
    sudo apt install -y jq
fi

if command -v wget &> /dev/null; then
    echo "wget is already installed"
else
    sudo apt install -y wget
fi

if command -v unzip &> /dev/null; then
    echo "unzip is already installed"
else
    sudo apt install -y unzip
fi


# Check if Terraform is installed
if command -v terraform &> /dev/null; then
    echo "Terraform is already installed"
else
    echo "Terraform not found, installing..."
    wget https://releases.hashicorp.com/terraform/1.5.7/terraform_1.5.7_linux_amd64.zip
    unzip terraform_1.5.7_linux_amd64.zip
    sudo mv terraform /usr/local/bin/
    rm terraform_1.5.7_linux_amd64.zip
fi

# Verify Terraform installation
terraform -v

# Check if Ansible is installed
if  command -v ansible &> /dev/null; then
    echo "Ansible is already installed"
else
    echo "Ansible not found, installing..."
    sudo apt install -y ansible
fi

# Verify Ansible installation
ansible --version

# Check if Vagrant is installed
if  command -v vagrant &> /dev/null; then
    echo "Vagrant is already installed"
else
    echo "Vagrant not found, installing..."
    wget https://releases.hashicorp.com/vagrant/2.3.7/vagrant_2.3.7_linux_amd64.zip
    unzip vagrant_2.3.7_linux_amd64.zip
    sudo mv vagrant /usr/local/bin/
    rm vagrant_2.3.7_linux_amd64.zip
fi

# Verify Vagrant installation
vagrant --version

# Check if OpenSSH client is installed
if  command -v ssh &> /dev/null; then
    echo "OpenSSH client is already installed"
else
    echo "OpenSSH client not found, installing..."
    sudo apt install -y openssh-client
fi

#check AWS CLI Installation
if  command -v aws &> /dev/null; then
    echo "AWS CLI is already installed"
else
    echo "AWS CLI not found, installing..."
    sudo apt install -y awscli
fi

# Verify OpenSSH client installation
ssh -V

# call script.sh
echo "AWS Configuration..."
sudo ./script.sh

# Initialize and apply Terraform configuration
echo "Terraform validation..."
terraform validate
echo "Initializing and applying Terraform configuration..."
terraform init
echo "Terraform plan..."
sudo terraform plan -out=tfplan
echo "Applying Terraform configuration..."
echo "Constructing the infrastructure..."
sudo  terraform apply tfplan


# For red_team
echo "Getting data to inventory.ini..."
echo "Red_team ip public adress..."
terraform output -json instance_public_ip | jq -r '.red_team' > $(pwd)/ansible/.env 
red_team_ip=$(cat $(pwd)/ansible/.env)
sudo $(pwd)/scripts/ssh.sh
echo "[red_team]" > $(pwd)/ansible/inventory.ini
echo "${red_team_ip} ansible_user=ubuntu ansible_ssh_private_key_file=$(pwd)/cyberrange-key.pem" >> $(pwd)/ansible/inventory.ini

# For blue_team

# echo "blue_team ip public adress..."
terraform output -json instance_public_ip | jq -r '.blue_team' > $(pwd)/ansible/.env 
blue_team_ip=$(cat $(pwd)/ansible/.env)
sudo $(pwd)/scripts/ssh.sh
echo "[blue_team]" >> $(pwd)/ansible/inventory.ini
echo "${blue_team_ip} ansible_user=ubuntu ansible_ssh_private_key_file=$(pwd)/cyberrange-key.pem" >> $(pwd)/ansible/inventory.ini

# echo "target ip public adress..."
terraform output -json instance_public_ip | jq -r '.target' > $(pwd)/ansible/.env 
target_ip=$(cat $(pwd)/ansible/.env)
sudo $(pwd)/scripts/ssh.sh
echo "[target]" >> $(pwd)/ansible/inventory.ini
echo "${target_ip} ansible_user=ubuntu ansible_ssh_private_key_file=$(pwd)/cyberrange-key.pem" >> $(pwd)/ansible/inventory.ini


# Exécution Ansible playbooks
echo "Executing Ansible playbooks..."
sudo ansible-playbook -i $(pwd)/ansible/inventory.ini  $(pwd)/ansible/red_team_playbook.yml -l red_team 
sudo ansible-playbook -i $(pwd)/ansible/inventory.ini $(pwd)/ansible/blue_team_playbook.yml -l blue_team
sudo ansible-playbook -i $(pwd)/ansible/inventory.ini $(pwd)/ansible/target_playbook.yml -l target

# # (Optionnel) 
# vagrant up
