# Security Implementation Guide

## Application Security (app.js)

### Security Features Implemented:

1. **Helmet.js** - Sets HTTP security headers
   - Prevents XSS (Cross-Site Scripting) attacks
   - Protects against clickjacking
   - Enforces HTTPS policies
   - Disables unsafe inline scripts

2. **Rate Limiting** - Prevents brute force and DDoS attacks
   - 100 requests per IP per 15 minutes
   - Configurable per route
   - Returns standardized rate limit headers

3. **Input Sanitization** - Prevents injection attacks
   - Sanitizes MongoDB queries
   - Prevents NoSQL injection
   - XSS prevention

4. **Request Validation**
   - JSON payload size limit: 10MB
   - URL-encoded payload size limit: 10MB
   - Prevents request bomb attacks

5. **Error Handling**
   - Generic error messages in production
   - Detailed errors only in development
   - Prevents information disclosure

6. **Logging & Monitoring**
   - Structured JSON logging
   - Request tracking with timestamps
   - IP address logging for security auditing

7. **Environment Variables**
   - Managed through GitHub Actions Secrets (not .env files)
   - Runtime injection of secrets
   - NODE_ENV support for different environments

8. **Graceful Shutdown**
   - Proper cleanup on SIGTERM
   - Connection draining
   - Process exit handling

### Environment Configuration

This project uses **GitHub Actions Secrets** for configuration management.

**Setup:**

1. Go to GitHub Repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add your secrets (examples: `PORT`, `NODE_ENV`, `AWS_REGION`, etc.)
4. GitHub Actions will inject them as environment variables at runtime

**Local Development:**

```bash
# Set environment variables directly
export PORT=3000
export NODE_ENV=development
npm start

# OR use command line
PORT=3000 NODE_ENV=development npm start
```

See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for complete secrets configuration guide.

### Running the Application

```bash
# Install dependencies
npm install

# Development (with auto-reload)
npm run dev

# Production
NODE_ENV=production npm start
```

## Infrastructure Security (Terraform)

### Infracost Recommendation - Addressed ✓

**Issue:** Public IP exposure increases attack surface
**Solution:**

- `associate_public_ip_address = false` - Instance has NO public IP
- NAT Gateway for outbound connectivity - All outbound traffic goes through NAT Gateway
- **Cost benefit:** NAT Gateway usage is more cost-effective than managing bastion hosts

### Network Architecture

```
┌─────────────────────────────────────────────────────────┐
│ VPC (10.0.0.0/16)                                       │
│                                                         │
│ ┌──────────────────┐         ┌─────────────────────┐  │
│ │ Public Subnet    │         │ Private Subnet      │  │
│ │ (10.0.2.0/24)    │         │ (10.0.1.0/24)       │  │
│ │                  │         │                     │  │
│ │ ┌──────────────┐ │  NAT    │ ┌─────────────────┐ │  │
│ │ │  NAT Gateway │─┼─Gateway─┤│   EC2 Instance  │ │  │
│ │ └──────────────┘ │         │ │  (SwiftPay)     │ │  │
│ │  EIP:            │         │ │ (Private IP)    │ │  │
│ │  203.x.x.x       │         │ └─────────────────┘ │  │
│ │                  │         │                     │  │
│ └──────────────────┘         └─────────────────────┘  │
│         │                              │              │
│         └──────────────────────────────┘              │
│                     │                                  │
│              Internet Gateway                          │
└──────────────────────┬──────────────────────────────────┘
                       │
                   Internet
```

### Security Features

1. **Network Isolation**
   - Private subnet for application server
   - No direct internet access to EC2 instance
   - Only outbound via NAT Gateway

2. **Security Groups**
   - Application SG: Only accepts traffic on port 3000 from VPC
   - Bastion SG: SSH access (restrict CIDR in production)
   - Explicit deny by default

3. **EBS Encryption**
   - Root volume encrypted at rest
   - gp3 volume type for better performance/cost

4. **OS Hardening**
   - Automatic security updates enabled
   - Fail2ban for SSH brute force protection
   - Unnecessary services disabled
   - Ubuntu 22.04 LTS (long-term support)

5. **IAM Role Ready** (Optional - not configured yet)
   - Can add IAM role for AWS service access
   - EC2 Instance Connect support
   - Systems Manager Session Manager support

### Outbound Connectivity

With NAT Gateway, your EC2 instance can:

- Download Node.js packages from npm registry
- Call external APIs
- Get security updates
- Reach AWS services (S3, CloudWatch, etc.)

All outbound traffic appears to originate from the NAT Gateway's Elastic IP.

### Accessing the Instance

Since the instance is in a private subnet, access via:

1. **AWS Systems Manager Session Manager** (Recommended)
   - No SSH keys needed
   - Requires IAM role attached to instance
   - Audit trail in CloudTrail

2. **Bastion Host** (Optional)

   ```bash
   ssh -i key.pem -J ubuntu@bastion-ip ubuntu@private-ip
   ```

3. **VPN** (For production)
   - Connect to VPC via VPN
   - Access instance directly

4. **Application Load Balancer (ALB)** (Recommended)
   - Place ALB in public subnet
   - Route traffic to private instance
   - Public access without public instance IP

### Production Recommendations

1. **Add Application Load Balancer (ALB)**

   ```hcl
   # Add to terraform/
   - Create ALB in public subnet
   - Route traffic to EC2 instance on port 3000
   - Use HTTPS with ACM certificate
   ```

2. **Bastion Host Configuration**

   ```hcl
   # Create bastion instance in public subnet
   # Add security group rule to allow SSH from bastion
   ingress {
     from_port       = 22
     to_port         = 22
     protocol        = "tcp"
     security_groups = [aws_security_group.bastion.id]
   }
   ```

3. **Enable AWS Systems Manager**
   - Attach IAM instance profile with SSM policy
   - Use Session Manager for shell access

4. **CloudWatch Monitoring**
   - Monitor NAT Gateway metrics
   - Set up alarms for high data transfer
   - Track failed connection attempts

5. **VPC Flow Logs**

   ```hcl
   # Add to terraform/
   resource "aws_flow_log" "main" {
     iam_role_arn    = aws_iam_role.vpc_flow_log.arn
     log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
     traffic_type    = "REJECT"
     vpc_id          = aws_vpc.swiftpay.id
   }
   ```

6. **WAF (Web Application Firewall)**
   - Protect ALB from common attacks
   - Rate limiting at CDN level
   - SQL injection and XSS prevention

7. **Secrets Management**
   - Use AWS Secrets Manager for credentials
   - Rotate secrets regularly
   - Limit access via IAM policies

## Deployment Steps

### 1. Update Terraform Variables

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit with your values:
# - key_pair_name: Your EC2 key pair
# - environment: dev/staging/prod
# - instance_type: t4g.micro for cost optimization
```

### 2. Initialize Terraform

```bash
terraform init
```

### 3. Review Changes

```bash
terraform plan
# Verify:
# - NAT Gateway will be created
# - EC2 instance will be in private subnet
# - No public IP assigned
```

### 4. Apply Configuration

```bash
terraform apply
# Review and confirm
```

### 5. Deploy Application

```bash
# SSH to instance or use Session Manager
# Then:
cd /opt/swiftpay
git clone <your-repo>
npm install
npm start
```

## Security Checklist

- [ ] GitHub Actions Secrets configured for all sensitive data
- [ ] .gitignore configured (node_modules/, etc.)
- [ ] Terraform state encrypted (S3 with encryption)
- [ ] EC2 key pair securely stored
- [ ] Security groups reviewed and tested
- [ ] NAT Gateway monitoring enabled
- [ ] CloudWatch alarms configured
- [ ] Application logging enabled
- [ ] Rate limiting tested
- [ ] HTTPS configured (ALB with ACM)
- [ ] Backup strategy defined
- [ ] Disaster recovery plan created
- [ ] Regular security updates scheduled
- [ ] VPC Flow Logs enabled
- [ ] CloudTrail enabled for audit logs

## Cost Implications

### Savings from Infracost Recommendation

- **No public IP management complexity**
- **NAT Gateway cost:** ~$32/month + data transfer ($0.045/GB)
- **Alternative (Bastion host):** 1 additional EC2 instance = $5-10/month + management overhead
- **Result:** NAT Gateway is more cost-effective and secure

## Troubleshooting

### Instance can't reach internet

1. Check NAT Gateway status: `aws ec2 describe-nat-gateways`
2. Verify route table: `aws ec2 describe-route-tables`
3. Check security group egress rules

### Can't SSH to instance

1. Use AWS Systems Manager Session Manager (no SSH needed)
2. Or create bastion host in public subnet
3. Or use EC2 Instance Connect

### High NAT Gateway costs

1. Review outbound traffic patterns
2. Consider VPC endpoints for AWS services
3. Implement caching for package managers
4. Use VPC endpoint for S3/DynamoDB access
