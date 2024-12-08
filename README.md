# Cyber-range-Infra-Automation

## Overview

The project aims to automate the development of computerized algorithms for attack simulations and cybersecurity defense exercises. Using DevOps tools, it enables test environments and custom applications designed for cybersecurity training environments.

## Key Features

- **Automated Attack Simulations:** Generate and execute realistic attack scenarios for Red/Blue Team exercises.
- **Dynamic Test Environments:** Easily deploy and manage isolated environments for various training modules.
- **DevOps Integration:** Streamline workflows using tools like Vault, Terraform, and Ansible.
- **Custom Applications:** Build adaptable solutions for specific cybersecurity training needs.

## Benefits

- **Efficient Training:** Accelerates the setup of training labs, saving time and resources.
- **Scalability:** Enables large-scale simulations with minimal resource overhead.
- **Real-World Scenarios:** Mimics actual cyberattack techniques and defense strategies.

## Technology Stack

- **Vagrant:** For creating and managing lightweight, reproducible, and portable virtual environments.
- **Terraform:** For Infrastructure as Code (IaC) deployment, enabling automated provisioning and resource management.
- **Ansible:** For configuration management and application deployment.
- **Vault:** For secure secrets management and protecting sensitive data.

## Use Cases

- **Red/Blue Team Simulations:** Practice real-time offensive and defensive cybersecurity strategies.
- **Penetration Testing Training:** Explore vulnerabilities in a controlled, customizable environment.
- **Incident Response Exercises:** Prepare teams for responding to various attack scenarios.

## Prerequisites

- **AWS Account:** Ensure you have access to an AWS account with the necessary permissions.
- **Terraform Installed:** [Download and install Terraform](https://www.terraform.io/downloads.html).
- **Ansible Installed:** [Download and install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- **Vagrant Installed:** [Download and install Vagrant](https://www.vagrantup.com/downloads).
- **SSH Key Pair:** Generate an SSH key pair (`cyberrange-key.pem`) and add the public key to your AWS account.

## Setup Instructions

1. **Clone the Repository:**   ```bash
   git clone https://github.com/zokevlar98/cyber-range-Infra-Automation.git
   cd cyber-range-Infra-Automation   ```

2. **Configure Terraform Backend:**
   - Create an S3 bucket and DynamoDB table as described in the [Terraform Backend Configuration](#2-configure-terraform-backend-for-state-management).

3. **Update Variables:**
   - Modify `variables.tf` to set your desired configurations, such as `aws_region`, `allowed_ip`, and `key_name`.

4. **Run Deployment Script:**   ```bash
   chmod +x deploy.sh
   ./deploy.sh   ```

5. **Access the Cyber Range:**
   - Use the generated `inventory.ini` to connect to your instances via SSH or access deployed services.

## Security Considerations

- **Restrict SSH Access:** Ensure that `var.allowed_ip` is set to your trusted IP range to prevent unauthorized access.
- **Manage Secrets Securely:** Use Ansible Vault or AWS Vault to manage sensitive information like SSH keys and AWS credentials.
- **Regular Updates:** Keep all software dependencies up-to-date to mitigate security vulnerabilities.

## Contribution

Contributions are welcome! Please open an issue or submit a pull request for any enhancements or bug fixes.

## License

[MIT License](LICENSE)
