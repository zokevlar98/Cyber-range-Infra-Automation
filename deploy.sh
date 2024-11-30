#!/bin/bash

# Update and upgrade the system
# sudo apt update && sudo apt upgrade -y

# check jq is installed or not
if ! command -v jq &> /dev/null; then
    sudo apt install -y jq
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

# Verify OpenSSH client installation
ssh -V

Initialize and apply Terraform configuration
echo "Terraform validation..."
terraform validate
echo "Initializing and applying Terraform configuration..."
terraform init
echo "Terraform plan..."
terraform plan -out=tfplan
echo "Applying Terraform configuration..."
echo "Constructing the infrastructure..."
terraform apply tfplan

# Execute Ansible playbooks
# r = "ansible/red_team_playbook.yml"
# b = "ansible/blue_team_playbook.yml"
# t = "ansible/target_playbook.yml"
sudo ansible-playbook -i $(pwd)/ansible/inventory.ini  $(pwd)/ansible/red_team_playbook.yml

# # Exécution des playbooks Ansible
# ansible-playbook -i inventory red_team_playbook.yml
# ansible-playbook -i inventory bue_team_playbook.yml
# ansible-playbook -i inventory target_playbook.yml

# # (Optionnel) Démarrage de Vagrant
# vagrant up

