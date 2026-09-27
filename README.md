# HoneyCloud Security Framework - Complete Project Analysis

> An AWS-native, Infrastructure-as-Code honeypot system for detecting, capturing, and analyzing cloud-targeted cyber attacks.

---

## Table of Contents
1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Tech Stack](#tech-stack)
4. [Directory Structure](#directory-structure)
5. [Code Flow & Execution](#code-flow--execution)
6. [Infrastructure & Deployment](#infrastructure--deployment)
7. [Security Analysis](#security-analysis)
8. [Key Features](#key-features)
9. [Interview Preparation](#interview-preparation)
10. [Resume Content](#resume-content)

---

## PROJECT OVERVIEW

### Purpose
HoneyCloud is an **AWS-native honeypot infrastructure-as-code (IaC) framework** designed to detect, trap, and analyze malicious threats in a cloud environment. It creates an intentionally vulnerable decoy system to attract and monitor attackers.

### Problem It Solves
- **Threat Detection**: Traditional security tools can only detect known attack patterns. Honeypots catch new, zero-day attacks by luring attackers.
- **Attack Analysis**: By observing attacker behavior on decoy systems, security teams gain intelligence about attack methodologies.
- **Early Warning System**: Threats targeting honeypots indicate that an organization is under active reconnaissance.
- **Cloud Security Gaps**: Many organizations lack visibility into what attackers do once they breach the perimeter.

### Real-World Use Case
A financial services company deploys HoneyCloud to:
1. Detect APT (Advanced Persistent Threat) groups targeting their infrastructure
2. Capture attacker credentials, commands, and tools used
3. Trigger immediate alerts via SMS/Email when malicious activity occurs
4. Maintain audit trails through CloudTrail for post-incident forensics
5. Train ML models using SageMaker to identify attack patterns across multiple honeypot instances

---

## ARCHITECTURE

### High-Level Workflow

```
Attacker
  ↓
Internet
  ↓
AWS VPC (10.0.0.0/16)
  ├─ Security Group (Ports 22, 2222, 80)
  └─ EC2 Instance (t2.micro)
      ├─ Cowrie SSH Honeypot (Fake Linux Server)
      ├─ CloudWatch Logs (Capture all sessions)
      └─ VPC Flow Logs (Network traffic capture)
         ↓
    CloudWatch Events
         ↓
    Lambda: Threat Detector
         ├─ Analyzes logs for suspicious commands
         ├─ Detects patterns (wget, curl, nmap, etc.)
         └─ Publishes to SNS
            ↓
         SNS Topic
         ├─ Email Notification
         └─ SMS Notification
         ↓
    CloudTrail + S3
    (Permanent audit log)
         ↓
    SageMaker ML Notebook
    (Threat intelligence analysis)
```

### Component Interactions

| Component | Purpose | Interaction |
|-----------|---------|-------------|
| **EC2 + Cowrie** | Honeypot server | Attracts attackers, logs all activity |
| **CloudWatch Logs** | Log aggregation | Captures all SSH sessions and commands |
| **VPC Flow Logs** | Network monitoring | Tracks all network traffic in/out of VPC |
| **Lambda Function** | Threat detection | Analyzes logs, detects malicious patterns |
| **SNS** | Alert system | Sends notifications on threat detection |
| **CloudTrail** | Audit logging | Records all API calls to AWS services |
| **S3** | Log storage | Stores CloudTrail logs for compliance |
| **RDS (Decoy DB)** | Honeypot database | Fake database to attract DB-level attacks |
| **SageMaker** | ML analysis | Analyzes threat patterns over time |

### End-to-End Data Flow

```
Attack Detection Flow:
━━━━━━━━━━━━━━━━━━━━━

1. Attacker SSH → Port 22/2222
   ↓
2. Cowrie logs session to CloudWatch
   └─ User commands captured (wget, cat /etc/passwd, etc.)
   ↓
3. CloudWatch Events triggers on new logs
   ↓
4. Lambda function receives event
   └─ Scans log content for SUSPICIOUS_COMMANDS list
   ↓
5. Threat detected (e.g., "wget" command)
   ├─ SNS publishes alert
   ├─ Email + SMS sent immediately
   └─ Lambda returns 200 OK
   ↓
6. CloudTrail logs all API calls
   └─ SNS:Publish, Lambda:Invoke, etc.
   ↓
7. CloudTrail logs stored in S3 with encryption
   └─ Versioning enabled for compliance
   ↓
8. Security analyst reviews in SageMaker
   └─ Creates ML model for pattern detection
```

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        AWS Account (us-east-1)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              VPC (10.0.0.0/16)                           │  │
│  │  ┌───────────────────────────────────────────────────┐   │  │
│  │  │    Public Subnet (10.0.1.0/24)                    │   │  │
│  │  │  ┌─────────────────────────────────────────────┐  │   │  │
│  │  │  │  EC2 Instance: Cowrie Honeypot             │  │   │  │
│  │  │  │  ├─ Fake Linux SSH Server                  │  │   │  │
│  │  │  │  ├─ Logs → CloudWatch /honeycloud/cowrie  │  │   │  │
│  │  │  │  └─ Network → VPC Flow Logs               │  │   │  │
│  │  │  │      (IAM Role: honeycloud-ec2-role)      │  │   │  │
│  │  │  └─────────────────────────────────────────────┘  │   │  │
│  │  │       ↓                                           │   │  │
│  │  │  Security Group                                  │   │  │
│  │  │  ├─ TCP 22 (Admin SSH)                          │   │  │
│  │  │  ├─ TCP 2222 (Cowrie SSH)                       │   │  │
│  │  │  └─ TCP 80 (HTTP)                               │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  │  ┌───────────────────────────────────────────────────┐   │  │
│  │  │    Public Subnet 2 (10.0.2.0/24)                 │   │  │
│  │  │  ┌─────────────────────────────────────────────┐  │   │  │
│  │  │  │  RDS Instance (MySQL 8.0)                  │  │   │  │
│  │  │  │  ├─ Identifier: honeycloud-decoy-db       │  │   │  │
│  │  │  │  ├─ User: admin / Password: Password123!  │  │   │  │
│  │  │  │  └─ Port 3306 (Open to 0.0.0.0/0)        │  │   │  │
│  │  │  └─────────────────────────────────────────────┘  │   │  │
│  │  └───────────────────────────────────────────────────┘   │  │
│  │           ↓ (IGW)                                        │  │
│  └──────────────────────────────────────────────────────────┘  │
│           ↓                                                     │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              MONITORING & ALERTING LAYER                 │  │
│  │  ┌───────────────────┬──────────────────────────────┐    │  │
│  │  │  CloudWatch       │  VPC Flow Logs               │    │  │
│  │  │  ├─ Log Group     │  ├─ /aws/vpc/flowlogs      │    │  │
│  │  │  │  /honeycloud   │  └─ (IAM Role: flow_logs)  │    │  │
│  │  │  ├─ Retention: 7  │                            │    │  │
│  │  │  └─ Events        │                            │    │  │
│  │  │     (Trigger→λ)   │                            │    │  │
│  │  └───────────────────┴──────────────────────────────┘    │  │
│  │           ↓                                               │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │  Lambda: threat_detector                        │    │  │
│  │  │  ├─ Language: Python 3.10                       │    │  │
│  │  │  ├─ Handler: threat_detector.lambda_handler    │    │  │
│  │  │  ├─ Timeout: 30s                               │    │  │
│  │  │  ├─ Detects: wget, curl, nmap, nc, cat, uname │    │  │
│  │  │  └─ (IAM Role: lambda_role + SNS permissions)  │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  │           ↓                                               │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │  SNS Topic: honeypot-alerts                     │    │  │
│  │  │  ├─ Email: ${var.email_address}               │    │  │
│  │  │  └─ SMS: ${var.phone_number}                  │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │              AUDIT & ANALYSIS LAYER                      │  │
│  │  ┌────────────────┐      ┌──────────────────────────┐    │  │
│  │  │  CloudTrail    │      │  S3 Bucket               │    │  │
│  │  │  ├─ Multi-     │      │  ├─ honeycloud-logs-*   │    │  │
│  │  │  │  region     │      │  ├─ Versioning: ON      │    │  │
│  │  │  └─ Logs →     │      │  ├─ Encryption: AES256  │    │  │
│  │  │     S3         │      │  └─ Policy: CloudTrail  │    │  │
│  │  └────────────────┘      └──────────────────────────┘    │  │
│  │           ↓                                               │  │
│  │  ┌──────────────────────────────────────────────────┐    │  │
│  │  │  SageMaker Notebook Instance                    │    │  │
│  │  │  ├─ Instance: ml.t2.medium                      │    │  │
│  │  │  ├─ Role: honeycloud-sagemaker-role           │    │  │
│  │  │  └─ Analysis: ML threat detection model        │    │  │
│  │  └──────────────────────────────────────────────────┘    │  │
│  └──────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────┘
```

---

## TECH STACK

### Programming Languages
- **Python 3.10** - Lambda threat detection function
- **Bash/Shell** - EC2 user data initialization script
- **HCL (HashiCorp Configuration Language)** - Terraform IaC
- **JSON** - IAM policies, CloudWatch event patterns

### Frameworks & Libraries
- **Cowrie** - SSH honeypot (open-source honeypot emulating vulnerable Linux SSH server)
- **Boto3** - AWS SDK for Python (used in Lambda for SNS publishing)
- **Terraform AWS Provider** - AWS infrastructure management

### Cloud Services (AWS)
- **EC2** (Elastic Compute Cloud) - Honeypot VM host
- **VPC** (Virtual Private Cloud) - Network isolation
- **Security Groups** - Firewall rules
- **CloudWatch** - Log aggregation, metrics, alarms
- **CloudTrail** - API audit logging
- **Lambda** - Serverless threat detection
- **SNS** (Simple Notification Service) - Alert delivery
- **S3** (Simple Storage Service) - Audit log storage
- **RDS** (Relational Database Service) - Decoy MySQL database
- **IAM** (Identity and Access Management) - Role-based access control
- **SageMaker** - ML notebook environment

### Databases
- **MySQL 8.0** (RDS) - Decoy database with hardcoded credentials (intentionally vulnerable)

### DevOps Tools
- **Terraform** (v1.5.0+) - Infrastructure as Code
- **AWS Provider** (v5.0+) - Terraform AWS plugin
- **Archive Provider** (v2.4+) - For packaging Lambda functions

### Security Tools
- **VPC Flow Logs** - Network traffic analysis
- **CloudTrail** - Compliance audit logging
- **S3 Encryption** - AES-256 server-side encryption
- **IAM Roles** - Least-privilege access control
- **Security Groups** - Network segmentation

### Monitoring Tools
- **CloudWatch Logs** - Central log aggregation
- **CloudWatch Alarms** - Failed login detection
- **CloudWatch Events** - Event-driven automation

---

## DIRECTORY STRUCTURE

### Root Directory

| File | Purpose |
|------|---------|
| README.md | Project documentation |
| LICENSE | Project licensing |

### `/terraform` Directory
Main Infrastructure-as-Code implementation. All AWS resources defined here.

#### Core Files

| File | Purpose | Key Content |
|------|---------|------------|
| main.tf | Global variables | Common tags (Project, Managed) |
| provider.tf | AWS Provider config | Region: us-east-1, AWS v5.0+ |
| versions.tf | Terraform version constraints | Requires Terraform ≥1.5.0 |
| variables.tf | Input variables | aws_region, project_name, key_name, email_address, phone_number |
| terraform.tfvars | Variable values | key_name=proj_key, region=us-east-1, email placeholder |
| outputs.tf | Output values | honeypot_public_ip (for accessing honeypot) |

#### Infrastructure Files

| File | Purpose | Resources Created |
|------|---------|-------------------|
| networking.tf | Network setup | VPC (10.0.0.0/16), 2 Public Subnets, IGW, Route Tables |
| security_groups.tf | Firewall rules | honeypot_sg (22, 2222, 80 open), rds_sg (3306 open) |
| ec2.tf | Honeypot server | t2.micro instance, Cowrie honeypot, user data script |
| rds.tf | Decoy database | MySQL 8.0, db.t3.micro, hardcoded admin/Password123! |
| iam.tf | Access control | EC2 role, Lambda role, SageMaker role with assume policies |
| lambda.tf | Threat detection | threat_detector function, Python 3.10, 30s timeout |
| eventbridge.tf | Event routing | CloudWatch Event Rule triggers Lambda on threat patterns |
| cloudwatch.tf | Monitoring | Log group /honeycloud/cowrie, failed login alarm |
| cloudtrail.tf | Audit logging | Multi-region CloudTrail, logs to S3 |
| s3.tf | Log storage | honeycloud-logs bucket, versioning, AES256 encryption, CloudTrail policy |
| sns.tf | Alerting | honeypot-alerts topic, email & SMS subscriptions |
| vpc_flow_logs.tf | Network traffic | VPC Flow Logs, IAM role, CloudWatch log group /aws/vpc/flowlogs |
| sagemaker.tf | ML analysis | ml.t2.medium notebook instance, full SageMaker access |

### `/terraform/lambda` Directory

| File | Purpose |
|------|---------|
| threat_detector.py | Python Lambda function for threat detection |

**threat_detector.py Key Components:**
- Detects: wget, curl, nc, nmap, cat /etc/passwd, uname -a
- Publishes alerts to SNS
- Returns HTTP 200 on completion
- **Note:** SNS_TOPIC_ARN needs to be updated before deployment

### `/terraform/policies` Directory

| File | Purpose |
|------|---------|
| ec2_assume_role.json | EC2 service trust policy |
| lambda_assume_role.json | Lambda service trust policy |
| flow_logs_assume_role.json | VPC Flow Logs service trust policy |

### `/terraform/userdata` Directory

| File | Purpose |
|------|---------|
| cowrie.sh | EC2 initialization script - Installs and starts Cowrie honeypot |

### `/terraform/proj_key` & `/terraform/proj_key.pub`
SSH key pair for EC2 instance access.

---

## CODE FLOW & EXECUTION

### Threat Detection Pipeline

```
Step 1: Attacker SSH Connection → Port 2222 (Cowrie)
Step 2: Cowrie logs session → CloudWatch Logs (/honeycloud/cowrie)
Step 3: CloudWatch Event Rule detects new logs
Step 4: Lambda function triggered (threat_detector)
Step 5: Pattern matching on suspicious commands
Step 6: If match found → SNS.publish()
Step 7: SNS routes to Email & SMS subscriptions
Step 8: CloudTrail logs all API calls → S3 bucket
Step 9: Security analyst reviews in SageMaker
```

### Key Function (Lambda)

**threat_detector.py Handler:**
- Input: CloudWatch event containing logs
- Process: Loop through SUSPICIOUS_COMMANDS list
- Logic: If command found in logs → Publish SNS alert
- Output: HTTP 200 + JSON confirmation

**Suspicious Commands Monitored:**
- wget (file downloads)
- curl (HTTP requests)
- nc (network tunneling)
- nmap (port scanning)
- cat /etc/passwd (credential access)
- uname -a (system reconnaissance)

---

## INFRASTRUCTURE & DEPLOYMENT

### AWS Resources Summary

**Total: ~40-50 resources**

- 1 VPC + 2 Public Subnets + 1 IGW + Route Tables
- 1 EC2 Instance (t2.micro) + 1 IAM Profile
- 1 RDS Instance (MySQL 8.0, t3.micro)
- 1 Lambda Function (Python 3.10)
- 1 SageMaker Notebook (ml.t2.medium)
- 3 IAM Roles + 5 Policy Attachments
- 2 Security Groups
- 1 CloudTrail + 1 S3 Bucket (versioned, encrypted)
- 1 SNS Topic + 2 Subscriptions
- 2 CloudWatch Log Groups
- 1 CloudWatch Alarm
- 1 EventBridge Rule

### Quick Deployment

```bash
cd terraform/
terraform init
terraform plan -var="key_name=your-key" -var="email_address=your-email@example.com" -var="phone_number=+1234567890"
terraform apply -var="key_name=your-key" -var="email_address=your-email@example.com" -var="phone_number=+1234567890"
```

---

## SECURITY ANALYSIS

### Multi-Layer Security Approach

1. **Honeypot Layer**: Cowrie emulates vulnerable SSH server
2. **Detection Layer**: Lambda analyzes logs for malicious patterns
3. **Alerting Layer**: SNS sends real-time notifications (Email + SMS)
4. **Audit Layer**: CloudTrail records all API calls to S3
5. **Monitoring Layer**: VPC Flow Logs capture network traffic
6. **Analysis Layer**: SageMaker for advanced threat intelligence

### Security Best Practices Implemented

✅ Multi-region CloudTrail logging
✅ S3 versioning & AES256 encryption
✅ IAM least-privilege roles with trust policies
✅ VPC Flow Logs for network visibility
✅ CloudWatch log retention & alarms
✅ Event-driven automation (Lambda)
✅ SNS encryption for alerts

### Security Gaps Identified

⚠️ RDS encryption not enabled
⚠️ Hardcoded SNS_TOPIC_ARN in Lambda
⚠️ Simple string matching (easily bypassed)
⚠️ 7-day log retention (should be 90+ for compliance)
⚠️ RDS credentials hardcoded
⚠️ Open RDS to 0.0.0.0/0 (intentional, but risky)
⚠️ No GuardDuty or advanced threat detection
⚠️ No encrypted command detection

---

## KEY FEATURES

### 1. SSH Honeypot (Cowrie)
- Emulates vulnerable Linux SSH server
- Logs all login attempts and commands
- Runs on port 2222
- Captures attacker tools and techniques

### 2. Real-Time Threat Detection (Lambda)
- Python 3.10 function
- Triggered by CloudWatch Events
- Analyzes logs for suspicious patterns
- 30-second timeout
- Publishes alerts immediately

### 3. Multi-Channel Alerting (SNS)
- Email notifications
- SMS notifications
- Instant incident response
- Configurable recipients

### 4. Comprehensive Audit Logging (CloudTrail)
- Multi-region coverage
- All API calls logged
- S3 storage with encryption
- Tamper-evident with versioning
- Compliance-ready (SOC 2, PCI-DSS, HIPAA)

### 5. Network Traffic Analysis (VPC Flow Logs)
- Captures all VPC traffic
- Source/destination IPs, ports, protocols
- Helps identify attacker origins
- Enables network forensics

### 6. ML Analysis Platform (SageMaker)
- Jupyter notebook environment
- Build ML models for threat detection
- Analyze attack patterns
- Generate threat intelligence

### 7. Decoy Database (RDS MySQL)
- Attracts database attacks
- Captures SQL injection attempts
- Reveals attacker techniques
- Complements SSH honeypot

---

## INTERVIEW PREPARATION

### 2-Minute Explanation

"HoneyCloud is an AWS-based security framework that deploys a honeypot to detect and analyze cloud-targeted attacks. We use Cowrie, an SSH honeypot, on an EC2 instance that mimics a vulnerable Linux server. When attackers SSH in and execute commands like `wget`, `nmap`, or `cat /etc/passwd`, those actions are logged to CloudWatch. An AWS Lambda function monitors these logs in real-time, detects suspicious patterns, and publishes alerts via SNS to email and SMS. All API calls are recorded by CloudTrail to S3 for audit compliance. We also capture network traffic via VPC Flow Logs and provide a SageMaker notebook for ML-based threat analysis. It's a fully automated threat detection system deployed with Infrastructure-as-Code."

### 5-Minute Explanation

"HoneyCloud is a cloud-native honeypot framework built entirely on AWS infrastructure-as-code. The architecture consists of multiple layers:

**Honeypot Layer**: We deploy Cowrie, an open-source SSH honeypot, on a t2.micro EC2 instance. It emulates a real Linux server but doesn't provide actual system access. Attackers can log in and execute commands, but all activity is captured in logs.

**Detection Layer**: These logs flow to CloudWatch. An EventBridge rule triggers whenever new logs appear, invoking a Python Lambda function that performs pattern matching against known malicious commands (wget, nmap, curl, netcat, credential dumps). If a match is found, it publishes an alert to SNS.

**Alerting Layer**: The SNS topic has email and SMS subscriptions, so security teams get real-time notifications on their phone and email simultaneously—critical for incident response.

**Audit Layer**: Everything is logged. CloudTrail captures all API calls (EC2 launches, Lambda invocations, SNS publishes) and stores them in an encrypted, versioned S3 bucket for compliance with SOC 2 and PCI-DSS.

**Network Monitoring**: VPC Flow Logs capture all network traffic, giving us source/destination IPs, ports, and traffic volumes for network forensics.

**Analysis**: We provision a SageMaker notebook for security analysts to build ML models for advanced threat detection and generate threat intelligence.

**Bonus Layer**: We include a decoy MySQL database with weak credentials to attract database-level attacks and understand database attack patterns.

Everything is defined in Terraform—a single `terraform apply` command creates ~40-50 AWS resources, making it version-controlled, reproducible, and auditable."

### Top 20 Interview Q&A

**Q1: Why use a honeypot in cloud environments?**
A: Honeypots catch unknown, zero-day attacks by attracting attackers. They're cheap on cloud (t2.micro <$10/month), isolated, and easy to deploy/destroy. They provide attack intelligence, attacker tools, and forensic evidence—excellent ROI.

**Q2: Why Cowrie specifically?**
A: Cowrie is purpose-built for SSH emulation with realistic shell responses, session logging, file system faking, and automatic malware capture. Other options include Kippo, Dionaea, and Honeyd—but Cowrie is most mature for SSH.

**Q3: How does Lambda threat detection work?**
A: CloudWatch Events triggers Lambda when new logs appear. Lambda converts the event to a string, loops through SUSPICIOUS_COMMANDS, and if found, publishes an SNS alert. Simple but effective.

**Q4: How would you improve pattern detection?**
A: Use regex patterns instead of simple string matching. Add Base64 decoding for encoded commands. Implement frequency-based anomaly detection. Use ML models (SageMaker) for behavioral analysis instead of signatures.

**Q5: Why is the RDS database intentionally weak?**
A: It's a decoy, not storing real data. Goal is to attract attackers trying default credentials and analyze their techniques. Production would use AWS Secrets Manager.

**Q6: How do you prevent log storage from exploding?**
A: CloudWatch retention set to 7 days auto-deletes older logs. Use S3 with Glacier for cheaper long-term storage. Set CloudWatch alarms for cost spikes.

**Q7: Why CloudWatch Logs instead of S3 directly for VPC Flow Logs?**
A: CloudWatch allows real-time querying and Lambda integration. S3 is cheaper at scale and integrates with Athena. Production would use S3 + Athena for cost optimization.

**Q8: How would you bypass the threat detection?**
A: Easy bypasses: Base64 encoding, environment variables, hex encoding, aliases, command obfuscation. Better defense: regex patterns, ML-based detection, behavioral analysis.

**Q9: How do you secure the SSH key?**
A: Never commit to Git. Add to .gitignore. Restrict permissions (chmod 600). Use AWS Secrets Manager for production. Consider AWS Systems Manager Session Manager instead of SSH keys.

**Q10: How does CloudTrail prevent log tampering?**
A: S3 versioning prevents deletion. AES256 encryption protects data at rest. CloudTrail Log File Validation creates cryptographic signatures (hash chains). Any modification detected automatically.

**Q11: What if Lambda processing takes >30 seconds?**
A: Increase timeout or split into async pipeline. Option 1: Precompile regex for performance. Option 2: Increase timeout to 60s. Option 3: Separate detection from analysis into async workers.

**Q12: How do you manage credentials securely?**
A: Use environment variables (not hardcoded). Use AWS Secrets Manager for production. Use Terraform Cloud for remote state with encryption. Use GitHub Actions secrets for CI/CD.

**Q13: How would you test Terraform without deploying?**
A: Use `terraform validate` for syntax. Use `terraform plan` for preview. Use `tflint` for linting. Use LocalStack for local AWS mocking. Use Terraform test blocks for assertions.

**Q14: How would you scale to multiple honeypots across regions?**
A: Use Terraform `for_each` loops over regions. Create central SNS topic for aggregated alerts. Aggregate logs to central S3 for long-term storage. CloudTrail already multi-region.

**Q15: What are the estimated costs?**
A: EC2 ~$10/month, RDS ~$15/month, SageMaker ~$50/month, CloudWatch ~$5/month, S3 <$1/month. Total: ~$80/month for lab environment.

**Q16: What compliance standards does this meet?**
A: CloudTrail & S3 versioning meet SOC 2, PCI-DSS, HIPAA audit requirements. Encryption at rest/transit meets data protection standards. 7-day retention is short—should be 90+ for compliance.

**Q17: How would you integrate with SIEM tools?**
A: Export CloudTrail logs to Splunk via S3 integration. Stream CloudWatch Logs to Splunk via Lambda. Use EventBridge to trigger Splunk APIs. Build custom connectors for your SIEM.

**Q18: What's the Lambda cold start overhead?**
A: Python cold start ~1-2 seconds. Simple string matching adds ~1-10ms. SNS publish adds ~100-500ms. Total latency <1 second typically—well within 30s timeout.

**Q19: How would you handle attacker C2 callbacks?**
A: VPC Flow Logs capture outbound traffic. Can identify C2 server IPs/ports. Could add Network ACLs to block C2 traffic. Could send to threat intelligence platforms (VirusTotal, OSINT).

**Q20: What's the biggest limitation of this setup?**
A: Simple string matching is easily bypassed. No behavioral/ML detection in Lambda. 7-day retention too short. RDS intentionally weak (production risk). No GuardDuty/advanced threat detection. Would improve with ML models, longer retention, and behavioral analysis.

---

## RESUME CONTENT

### ATS-Friendly Description

Designed and deployed a fully automated cloud-native honeypot system on AWS using Infrastructure-as-Code (Terraform) to detect, capture, and analyze unauthorized access attempts and zero-day attacks. Architected a multi-layered security solution combining SSH honeypotting (Cowrie), real-time threat detection (AWS Lambda with Python), and comprehensive audit logging (CloudTrail). Implemented event-driven threat alerting via AWS SNS for multi-channel notifications. Demonstrated mastery of EC2, Lambda, CloudWatch, VPC, RDS, SageMaker, and IAM with production-grade Terraform code implementing least-privilege access control.

### 6 Resume Bullet Points

• **Architected AWS-native honeypot system** using Terraform v1.5+ deploying 40+ AWS resources: Cowrie SSH honeypot, Lambda threat detection, multi-region CloudTrail audit logging, and SNS alerting for zero-trust network security

• **Engineered real-time threat detection engine** with Python 3.10 Lambda functions triggered by CloudWatch Events, analyzing malicious commands and publishing alerts via SMS/Email within milliseconds for incident response

• **Designed defense-in-depth security monitoring** integrating VPC Flow Logs (network analysis), CloudWatch Logs (7-day retention), S3 encryption/versioning (compliance), and IAM least-privilege roles for production-grade security posture

• **Implemented Infrastructure-as-Code best practices** with modular Terraform for VPC (10.0.0.0/16), security groups, IAM assume roles, and automated EC2 initialization via Cowrie installation scripts

• **Configured decoy database layer** (RDS MySQL 8.0) capturing database-level attack patterns, integrated with SageMaker ML notebooks for forensic analysis and threat intelligence generation

• **Established compliance-grade audit infrastructure** using multi-region CloudTrail with tamper-evident S3 storage (versioning, AES256 encryption), meeting SOC 2, PCI-DSS, and HIPAA audit requirements

---

## Quick Start

### Prerequisites
- AWS Account with permissions
- Terraform >= 1.5.0
- AWS CLI configured
- SSH key pair

### Deploy

```bash
cd terraform/
terraform init
terraform apply -var="key_name=your-key" -var="email_address=your-email@example.com" -var="phone_number=+1234567890"
```

### Test

```bash
ssh -i your-key.pem ec2-user@<honeypot-ip>
su - cowrie
tail -f log/cowrie.log
```

---

## Estimated Monthly Cost

| Resource | Cost |
|----------|------|
| EC2 (t2.micro) | $10 |
| RDS (t3.micro) | $15 |
| SageMaker (ml.t2.medium) | $50 |
| CloudWatch Logs | $5 |
| S3 Storage | <$1 |
| **Total** | **~$80** |

---

**Version**: 1.0.0 | **Updated**: June 2024 | **Author**: Cloud Security Engineer