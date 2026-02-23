# AWS High Availability Production Infrastructure  
## Terraform-Based Multi-AZ Resilient Architecture

---

## Project Overview

This repository contains a production-grade AWS infrastructure provisioned entirely using Terraform. The architecture is designed to deliver high availability, fault tolerance, security isolation, and scalable application deployment across multiple Availability Zones.

The implementation aligns with AWS Well-Architected Framework principles and demonstrates enterprise-level infrastructure automation using Infrastructure as Code (IaC).

---

## Architecture Diagram

![AWS High Availability Architecture](architecture/aws-ha-architecture.png)

---

## Architectural Design

The solution follows a multi-tier architecture pattern consisting of:

- Internet-facing Load Balancing Layer
- Private Application Layer
- Private Database Layer
- Centralized Remote State Management

All resources are provisioned programmatically using Terraform to ensure repeatability, version control, and consistent deployments across environments.

---

## Networking Architecture

- Custom Virtual Private Cloud (VPC) — 10.10.0.0/16
- Two Public Subnets (Multi-AZ)
- Two Private Subnets (Multi-AZ)
- Internet Gateway
- Dedicated NAT Gateway per Availability Zone
- Public and Private Route Tables

Public subnets host ingress components, while private subnets isolate compute and database resources from direct internet access.

---

## Load Balancing Layer

- Application Load Balancer (ALB)
- Deployed across multiple Availability Zones
- HTTP Listener (Port 80)
- Target Group with health checks

The ALB distributes traffic only to healthy instances and ensures continuous availability during instance failures.

---

## Compute Layer

- Launch Template (Amazon Linux 2023)
- Auto Scaling Group
- Minimum capacity: 2 instances
- Maximum capacity: 4 instances
- Instances deployed in private subnets

The Auto Scaling Group ensures automatic recovery, load distribution across Availability Zones, and elasticity under traffic fluctuations.

---

## Database Layer

- Amazon RDS (MySQL 8.0)
- Multi-AZ Deployment enabled
- Private subnet placement
- Not publicly accessible
- Automated backups (7-day retention)

Automatic failover is enabled to ensure database resilience.

---

## Security Model

Strict security group segmentation enforces controlled traffic flow:

- **ALB Security Group** – Allows inbound HTTP/HTTPS from the internet
- **EC2 Security Group** – Allows traffic only from the ALB security group
- **RDS Security Group** – Allows database access only from the EC2 security group

No direct public access is permitted to application or database servers.

---

## Terraform State Management

- Amazon S3 Remote Backend
- Versioning Enabled
- DynamoDB Table for State Locking
- Server-Side Encryption Enabled

This configuration ensures safe collaboration, state consistency, and protection against concurrent modifications.

---

## Traffic Flow

1. User request enters through the internet.
2. Application Load Balancer receives and distributes traffic.
3. Healthy EC2 instances in private subnets process requests.
4. EC2 communicates with the Multi-AZ RDS database.
5. Response is returned to the user via the ALB.
6. Private instances access external services through NAT Gateways when required.

---

## Repository Structure
aws-ha-prod-infra/
├── main.tf
├── variables.tf
├── outputs.tf
├── provider.tf
├── README.md
└── architecture/
    └── aws-ha-architecture.png

---

## Deployment

Initialize and deploy infrastructure:
terraform init
terraform plan
terraform apply


---

## Key Highlights

- Multi-AZ High Availability Architecture
- Private Application and Database Isolation
- Automated Instance Scaling
- Production-Ready Remote Backend
- Fully Declarative Infrastructure
- Designed for Reliability and Operational Excellence

---

## Conclusion

This project demonstrates the ability to design and deploy resilient AWS infrastructure using Terraform, incorporating high availability, security segmentation, automated scaling, and production-ready state management practices.

It reflects real-world DevOps implementation standards suitable for enterprise cloud environments.
