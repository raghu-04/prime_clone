#!/bin/bash

# Get Public IP from Terraform output
PUBLIC_IP=$(terraform output -raw PUBLIC-IP)

# Fetch Jenkins password via SSH
PASSWORD=$(ssh -i test.pem ubuntu@$PUBLIC_IP "sudo cat /var/lib/jenkins/secrets/initialAdminPassword" 2>/dev/null)

# Print the details
echo "Access Jenkins Server here --> http://$PUBLIC_IP:8080"
echo "Jenkins Initial Password: $PASSWORD"
echo "Access SonarQube Server here --> http://$PUBLIC_IP:9000"
echo "SonarQube Username & Password: admin"
