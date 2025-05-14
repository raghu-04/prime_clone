resource "aws_security_group" "my-sg" {
    name = "JENKINS-SERVER-SG"
    description = "Jenkins server ports"

    #Port 22 for SSH 
    ingress {
        description = "SSH Port"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Port 80 fot HTTP
    ingress {
        description = "HTTP Port"
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Port 443 for https
    ingress {
        description = "HTTPS Port"
        from_port = 443
        to_port = 443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Port for etcd cluster 2379-2380
    ingress {
        description = "etcd cluster port"
        from_port = 2379
        to_port = 2380
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #NPM Port 3000
    ingress {
        description = "NPM Port"
        from_port = 3000
        to_port = 3000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Kube API server port 6443
    ingress {
        description = "Kube API server port"
        from_port = 6443
        to_port = 6443
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Jenkins port 8080
    ingress{
        description = "Port for jenkins"
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #SonarQube port 9000
    ingress {
        description = "Sonarqube port"
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Prometheus
    ingress {
        description = "Promethues port"
        from_port = 9090
        to_port = 9090
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #promethues metrix port
    ingress {
        description = "Promethues metrix port"
        from_port = 9100
        to_port = 9100
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Kubernetes port
    ingress {
        description = "K8s port"
        from_port = 10250
        to_port = 10260
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #NodePort k8's
    ingress {
        description = "kubernetes Node port"
        from_port = 30000
        to_port = 32767
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    #Outbound rules 
    egress {
        description = "allowing all incoming traffic"
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


# Creating EC2_server 

resource "aws_instance" "my_ec2" {
    ami = var.ami_id
    instance_type = var.instance_type
    key_name = var.key_name
    vpc_security_group_ids = [aws_security_group.my-sg.id]

    root_block_device {
      volume_size = var.volume_size
    }

    tags = {
      Name = var.server_name
    }

    #provisioning the ec2_server
    #create resources on created server using remote exec server
    provisioner "remote-exec" {
        #Establishing ssh connection to ec2_server
        connection {
          type = "ssh"
          private_key = file("./test.pem")
          user = "ubuntu"
          host = self.public_ip
        }

        inline = [
            "sudo apt-get update -y",

            #Install awscli
            "sudo apt install unzip -y",
            "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
            "unzip awscliv2.zip",
            "sudo ./aws/install",

            #Install Docker
            "sudo apt-get update -y",
            "sudo apt-get install -y ca-certificates curl",
            "sudo install -m 0755 -d /etc/apt/keyrings",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc",
            "sudo chmod a+r /etc/apt/keyrings/docker.asc",
            "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "sudo apt-get update -y",
            "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
            "sudo usermod -aG docker ubuntu",
            "sudo chmod 777 /var/run/docker.sock",
            "docker --version",

            #installing sonarqube as a container
            "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",

            #install Trivy
            "sudo apt-get install -y wget apt-transport-https gnupg",
            "wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null",
            "echo 'deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb generic main' | sudo tee -a /etc/apt/sources.list.d/trivy.list",
            "sudo apt-get update -y",
            "sudo apt-get install trivy -y",

            #install kubectl -- https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
            "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl",
            "curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.30.4/2024-09-11/bin/linux/amd64/kubectl.sha256",
            "sha256sum -c kubectl.sha256",
            "openssl sha1 -sha256 kubectl",
            "chmod +x ./kubectl",
            "mkdir -p $HOME/bin && cp ./kubectl $HOME/bin/kubectl && export PATH=$HOME/bin:$PATH",
            "echo 'export PATH=$HOME/bin:$PATH' >> ~/.bashrc",
            "sudo mv $HOME/bin/kubectl /usr/local/bin/kubectl",
            "sudo chmod +x /usr/local/bin/kubectl",
            "kubectl version --client",

            #install helm vesion
            "wget https://get.helm.sh/helm-v3.16.1-linux-amd64.tar.gz",
            "tar -zxvf helm-v3.16.1-linux-amd64.tar.gz",
            "sudo mv linux-amd64/helm /usr/local/bin/helm",
            "helm version",

            #argoCD installation
            "VERSION=$(curl -L -s https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION)",
            "curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/v$VERSION/argocd-linux-amd64",
            "sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd",
            "rm argocd-linux-amd64",

            #Install Java17
            "sudo apt update -y",
            "sudo apt install openjdk-17-jdk openjdk-17-jre -y",
            "java -version",

            #install jenkins
            "sudo wget -O /usr/share/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key",
            "echo \"deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/\" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
            "sudo apt-get update -y",
            "sudo apt-get install -y jenkins",
            "sudo systemctl start jenkins",
            "sudo systemctl enable jenkins",

            #Installed required applications and now
            #Getting jenkins inital password
            "ip=$(curl -s ifconfig.me)",
            "pass=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)",

            #output
            #access jenkins server
            "echo 'Access Jenkins Server here --> http://'$ip':8080'",
            "echo 'Jenkins Initial Password: '$pass''",
            "echo 'Access SonarQube Server here --> http://'$ip':9000'",
            "echo 'SonarQube Username & Password: admin'",

        ]
    }
}

#GET EC2 USERNAME AND PUBLIC IP
output "SERVER-SSH-ACCESS" {
  value = "ubuntu@${aws_instance.my_ec2.public_ip}"
}

#GET EC2 PUBLIC IP 
output "PUBLIC-IP" {
  value = "${aws_instance.my_ec2.public_ip}"
}

#GET EC2 PRIVATE IP 
output "PRIVATE-IP" {
  value = "${aws_instance.my_ec2.private_ip}"
}

