# Deloyment Guide - DeployReady Kora App

This document outlines the deployment procedures for the **Kora Analytics API** (`dev-ops/DeployReady/app`) on **Amazon EC2** behind Docker, and how to verify it is running.

---

## 1. EC2 Instance Setup (AWS Console)
An EC2 instance was provisioned using the AWS Console with the following configuration:

* Instance Name: koraapp-server
* Instance Type: t3.micro # t3.micro could not be used as it's no longer part of the free tier machine
* AMI: Amazon Linux 2023
* Key Pair for authentication: `koraappkey.pem` - An ED25519 SSH Key Pair was utilized to comply with AL2023's modern cryptographic standards
* **Security Group (`deployready-api-sg`):**
  * **Ingress Port 80 (HTTP):** Open to `0.0.0.0/0` for global http access.
  * **Ingress Port 22 (SSH):** Open to only my host ip
![alt text](imgs\instance.png)

## 2. How to check if the container is running
Upon initial boot, the following commands were executed to SSH into the host environment and prepare it for the container runtime:

```bash
ssh -i koraappkey.pem ec2-user@3.250.223.186
sudo dnf update -y
sudo dnf install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
```
The configuration to build and pull the docker image is defined inside the workflow(`.github/workflowa.deploy.yml`)

![alt text](imgs\docker_cont.png)

## 3. How to check if the container is running
The command to check if the container is running is `docker container ls`

## 4. How to view the application logs
To view the application logs run: `docker logs kora-app`
![alt text](imgs\app_logs.png)

Screenshot of the app ui
![alt text](imgs\app_healthcheck.png)
