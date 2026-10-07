\# Zero-Touch Deployments — Terraform + GitHub Actions + AWS ECS



Production-grade DevOps deployment platform for an e-commerce application using Terraform, AWS ECS Fargate, Amazon ECR, Application Load Balancer, CloudWatch, and GitHub Actions.



The platform removes manual production deployment steps and provides:



\- Infrastructure as Code with Terraform

\- Modular AWS infrastructure

\- Remote Terraform state with S3

\- DynamoDB state locking

\- Docker image build and ECR push

\- Pull Request validation

\- Automatic staging deployment

\- Production deployment with manual approval

\- ECS health checks

\- ECS deployment circuit breaker

\- Automatic rollback

\- ECS autoscaling from 2 to 6 tasks

\- CloudWatch logging and monitoring



\---



\## 1. Architecture



```text

&#x20;                        Developer

&#x20;                            |

&#x20;                            | git push

&#x20;                            v

&#x20;                   +------------------+

&#x20;                   |     GitHub       |

&#x20;                   |   Repository     |

&#x20;                   +--------+---------+

&#x20;                            |

&#x20;                   Pull Request

&#x20;                            |

&#x20;                            v

&#x20;                +----------------------+

&#x20;                | GitHub Actions       |

&#x20;                | Terraform Validate  |

&#x20;                | TFLint               |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                           v

&#x20;                +----------------------+

&#x20;                | Docker Build         |

&#x20;                | ECR Push             |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                           v

&#x20;                +----------------------+

&#x20;                | Staging Environment  |

&#x20;                | ECS Fargate          |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                      PR approved

&#x20;                           |

&#x20;                           v

&#x20;                    Merge to main

&#x20;                           |

&#x20;                           v

&#x20;                +----------------------+

&#x20;                | Production Approval  |

&#x20;                | GitHub Environment   |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                      Manual approval

&#x20;                           |

&#x20;                           v

&#x20;                +----------------------+

&#x20;                | Production ECS       |

&#x20;                | Fargate Service       |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                           v

&#x20;                +----------------------+

&#x20;                | Application Load     |

&#x20;                | Balancer             |

&#x20;                +----------+-----------+

&#x20;                           |

&#x20;                           v

&#x20;                      Application

&#x20;                           |

&#x20;                      /health check

2\. AWS Architecture



The infrastructure is provisioned using Terraform.



AWS Region: ap-south-1



VPC

|

+-- Public Subnets

|   |

|   +-- Application Load Balancer

|   +-- NAT Gateway

|

+-- Private Subnets

&#x20;   |

&#x20;   +-- ECS Fargate Tasks

&#x20;       |

&#x20;       +-- Application Container

&#x20;       |

&#x20;       +-- CloudWatch Logs

AWS Services

Service	Purpose

Amazon VPC	Network isolation

Public Subnets	ALB and NAT Gateway

Private Subnets	ECS application tasks

Internet Gateway	Public internet access

NAT Gateway	Outbound internet access from private subnets

Application Load Balancer	HTTP traffic distribution

ECS Fargate	Container orchestration

Amazon ECR	Docker image registry

IAM	ECS task execution permissions

CloudWatch	Logs, metrics and alarms

S3	Terraform remote state

DynamoDB	Terraform state locking

3\. Terraform Structure

terraform/

├── backend.tf

├── main.tf

├── outputs.tf

├── providers.tf

├── variables.tf

├── versions.tf

└── modules/

&#x20;   ├── networking/

&#x20;   │   ├── main.tf

&#x20;   │   ├── variables.tf

&#x20;   │   └── outputs.tf

&#x20;   │

&#x20;   ├── security/

&#x20;   │   ├── main.tf

&#x20;   │   ├── variables.tf

&#x20;   │   └── outputs.tf

&#x20;   │

&#x20;   ├── compute/

&#x20;   │   ├── main.tf

&#x20;   │   ├── variables.tf

&#x20;   │   └── outputs.tf

&#x20;   │

&#x20;   └── monitoring/

&#x20;       ├── main.tf

&#x20;       └── variables.tf

Terraform Modules

Networking



Creates:



VPC

Internet Gateway

Public subnets

Private subnets

Public route table

Private route table

NAT Gateway

Elastic IP

Security



Creates:



ALB security group

ECS security group



Traffic flow:



Internet

&#x20;  |

&#x20;  v

ALB :80

&#x20;  |

&#x20;  v

ECS :5000



ECS tasks do not accept direct public traffic.



Compute



Creates:



ECR repository

ECS cluster

ECS task definition

ECS Fargate service

Application Load Balancer

Target group

ALB listener

ECS execution IAM role

CloudWatch log group

Monitoring



Creates:



ECS CPU autoscaling

CloudWatch CPU alarm

CloudWatch deployment log group



Autoscaling configuration:



Minimum tasks: 2

Maximum tasks: 6

Target CPU:    60%

4\. Terraform Remote State



Terraform state is stored remotely using Amazon S3.



S3 Bucket

&#x20;   |

&#x20;   +-- terraform.tfstate



DynamoDB

&#x20;   |

&#x20;   +-- State locking



Remote state prevents local state from becoming the source of truth and DynamoDB prevents simultaneous Terraform operations from corrupting state.



Terraform backend configuration:



terraform {

&#x20; backend "s3" {

&#x20;   bucket         = "infra-as-code-pipeline-terraform-state-09-rs"

&#x20;   key            = "terraform.tfstate"

&#x20;   region         = "ap-south-1"

&#x20;   dynamodb\_table = "infra-as-code-pipeline-terraform-locks"

&#x20;   encrypt        = true

&#x20; }

}

5\. Application



The application is a lightweight Python HTTP service.



Port:



5000



Health endpoint:



GET /health



Expected response:



{

&#x20; "status": "healthy",

&#x20; "version": "v2",

&#x20; "service": "infra-as-code-pipeline"

}



Docker image:



python:3.12-alpine



Application image is stored in Amazon ECR.



6\. Docker



Application Dockerfile:



FROM python:3.12-alpine



WORKDIR /app



COPY app.py .



EXPOSE 5000



CMD \["python", "app.py"]



Build locally:



docker build -t infra-as-code-pipeline-app:v1 ./app



Run locally:



docker run -d \\

&#x20; --name infra-app-test \\

&#x20; -p 5000:5000 \\

&#x20; infra-as-code-pipeline-app:v1



Test:



curl http://localhost:5000/health

7\. CI/CD Pipeline



GitHub Actions implements the zero-touch deployment workflow.



Developer

&#x20;   |

&#x20;   v

Feature Branch

&#x20;   |

&#x20;   v

Pull Request

&#x20;   |

&#x20;   +----------------------+

&#x20;   |                      |

&#x20;   v                      v

Terraform Validate       TFLint

&#x20;   |                      |

&#x20;   +----------+-----------+

&#x20;              |

&#x20;              v

&#x20;         Docker Build

&#x20;              |

&#x20;              v

&#x20;           ECR Push

&#x20;              |

&#x20;              v

&#x20;       Staging Deployment

&#x20;              |

&#x20;              v

&#x20;       PR Review / Merge

&#x20;              |

&#x20;              v

&#x20;            main

&#x20;              |

&#x20;              v

&#x20;    Production Approval

&#x20;              |

&#x20;              v

&#x20;      Production ECS

&#x20;              |

&#x20;              v

&#x20;      Health Validation

&#x20;              |

&#x20;        +-----+-----+

&#x20;        |           |

&#x20;      Success      Failure

&#x20;        |           |

&#x20;        v           v

&#x20;      Done       Rollback

8\. Pull Request Workflow



Pull Requests targeting main run:



Terraform Format Check

&#x20;       |

Terraform Validate

&#x20;       |

TFLint

&#x20;       |

Docker Build

&#x20;       |

ECR Push

&#x20;       |

Staging ECS Deployment



Production deployment is not performed from the Pull Request.



This allows changes to be validated in staging before production.



9\. Production Workflow



After the Pull Request is merged into main:



main

&#x20;|

&#x20;v

Terraform Validation

&#x20;|

&#x20;v

Production Deployment Job

&#x20;|

&#x20;v

GitHub Production Environment

&#x20;|

&#x20;v

Manual Approval

&#x20;|

&#x20;v

ECS Deployment

&#x20;|

&#x20;v

Health Check

&#x20;|

&#x20;+---- Success ---> Deployment complete

&#x20;|

&#x20;+---- Failure ---> Automatic rollback



The production environment uses GitHub deployment protection with required reviewers.



This prevents an unapproved commit from directly reaching production.



10\. ECS Health Checks



The application container provides:



/health



The Application Load Balancer also checks:



HTTP :5000/health



Health check configuration:



Protocol: HTTP

Path: /health

Port: 5000

Healthy threshold: 2

Unhealthy threshold: 3

Interval: 30 seconds

Timeout: 5 seconds



ECS also uses a deployment circuit breaker with rollback enabled.



deployment\_circuit\_breaker {

&#x20; enable   = true

&#x20; rollback = true

}

11\. Automatic Rollback



Before production deployment, the workflow records the current ECS task definition.



Current Task Definition

&#x20;         |

&#x20;         v

Deploy New Task Definition

&#x20;         |

&#x20;         v

Wait for ECS Stability

&#x20;         |

&#x20;     +---+---+

&#x20;     |       |

&#x20;  Healthy  Failed

&#x20;     |       |

&#x20;     v       v

&#x20;  Success  Previous

&#x20;           Task Definition

&#x20;                |

&#x20;                v

&#x20;             Rollback



The GitHub Actions workflow restores the previous task definition if the production deployment fails.



ECS deployment circuit breaker rollback is also enabled at the infrastructure level.



This protects production from unhealthy deployments.



12\. Autoscaling



The ECS service is configured for target-tracking CPU autoscaling.



Minimum: 2 tasks

Maximum: 6 tasks

Target CPU: 60%



Example:



Normal load

&#x20;   |

&#x20;   v

2 ECS tasks



High CPU

&#x20;   |

&#x20;   v

3 → 4 → 5 → 6 tasks



Low CPU

&#x20;   |

&#x20;   v

Tasks scale back toward 2

13\. Monitoring



CloudWatch provides:



ECS CPU metrics

ECS CPU alarm

Application logs

Deployment logs



Log group:



/ecs/infra-as-code-pipeline



Deployment log group:



/ecs/infra-as-code-pipeline/deployment



Log retention:



7 days

14\. Setup Instructions

Prerequisites



Install/configure:



Git

Docker

AWS CLI

Terraform

GitHub account

AWS IAM credentials



Configure AWS:



aws configure



Verify:



aws sts get-caller-identity

15\. Terraform Deployment



Initialize:



terraform -chdir=terraform init



Format:



terraform -chdir=terraform fmt -recursive



Validate:



terraform -chdir=terraform validate



Plan:



terraform -chdir=terraform plan



Apply:



terraform -chdir=terraform apply



View outputs:



terraform -chdir=terraform output

16\. GitHub Actions Configuration



Required GitHub repository secrets:



AWS\_ACCESS\_KEY\_ID

AWS\_SECRET\_ACCESS\_KEY



GitHub Environments:



staging

production



Production environment requires reviewer approval.



17\. Deployment Runbook

Deploy a change

1\. Create feature branch

2\. Modify application/infrastructure

3\. Commit changes

4\. Push feature branch

5\. Create Pull Request

6\. Terraform validation runs

7\. TFLint runs

8\. Docker image is built

9\. Image is pushed to ECR

10\. Staging deployment runs

11\. Review staging result

12\. Merge Pull Request

13\. Production approval is requested

14\. Approve production deployment

15\. ECS deploys new task definition

16\. ECS waits for service stability

17\. Health check confirms application health

18\. Rollback Runbook



If a production deployment fails:



GitHub Actions detects deployment failure.

Previous ECS task definition is retrieved.

ECS service is updated to the previous task definition.

ECS starts the previous healthy tasks.

Workflow waits for ECS service stability.

Deployment is considered recovered.



Manual verification:



aws ecs describe-services \\

&#x20; --cluster infra-as-code-pipeline-cluster \\

&#x20; --services infra-as-code-pipeline-service



Check the application:



curl http://<ALB-DNS>/health

19\. Production Verification



Check ECS:



aws ecs describe-services \\

&#x20; --cluster infra-as-code-pipeline-cluster \\

&#x20; --services infra-as-code-pipeline-service



Expected:



Desired: 2

Running: 2

Pending: 0

Status: ACTIVE



Check application:



curl http://<ALB-DNS>/health



Expected:



{

&#x20; "status": "healthy",

&#x20; "version": "v2",

&#x20; "service": "infra-as-code-pipeline"

}

20\. Cost Considerations



The main AWS cost drivers are:



Resource	Cost consideration

ECS Fargate	Charged for running task CPU and memory

NAT Gateway	Hourly charge plus data processing

Application Load Balancer	Hourly and usage-based charges

ECR	Image storage and data transfer

CloudWatch	Logs, metrics and alarms

S3	Terraform state storage

DynamoDB	Terraform locking

VPC	Base VPC resources are generally free



For development/testing, infrastructure should be destroyed when it is no longer required to avoid unnecessary AWS charges.



Destroy:



terraform -chdir=terraform destroy



Before destroying production infrastructure, verify the target AWS account and Terraform state.



21\. Security



The project follows these security practices:



ECS tasks run in private subnets.

ALB is exposed publicly.

ECS security group only accepts application traffic from the ALB security group.

Terraform state is encrypted in S3.

Production deployment requires approval.

Infrastructure is managed through Terraform rather than manual console changes.

Application secrets are not committed to Git.

AWS credentials are stored as GitHub Actions secrets.

22\. GitOps / Infrastructure as Code Principles



Infrastructure changes are committed to Git.



Git

&#x20;|

&#x20;v

Pull Request

&#x20;|

&#x20;v

Review

&#x20;|

&#x20;v

GitHub Actions

&#x20;|

&#x20;v

Terraform / ECS



Manual production infrastructure modification is avoided.



The Git repository acts as the source of truth for infrastructure and deployment configuration.



23\. Project Outcome



The original deployment process required manual server access and deployment steps.



The final platform provides:



Manual SSH Deployment

&#x20;       |

&#x20;       v

Zero-Touch Deployment



The completed platform supports:



Terraform-managed AWS infrastructure

Modular infrastructure design

Remote state and locking

Containerized application deployment

Amazon ECR

ECS Fargate

Application Load Balancer

Private application networking

Autoscaling

CloudWatch monitoring

Pull Request validation

Staging deployment

Production approval

Automatic production rollback

Health validation

Git-based infrastructure changes

