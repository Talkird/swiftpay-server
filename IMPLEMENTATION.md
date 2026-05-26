# SwiftPay Server - Security Implementation

This document outlines the security improvements made to the SwiftPay Server application and infrastructure.

## 📋 Overview

The SwiftPay Server now includes enterprise-grade security across both the Node.js application and AWS infrastructure, with special attention to the Infracost recommendation about disabling public IP addresses.

## 🔒 Application Security Enhancements

### Dependencies Added

```json
{
  "helmet": "^7.1.0", // HTTP security headers
  "express-rate-limit": "^7.1.5", // Rate limiting
  "express-mongo-sanitize": "^2.2.0", // Input sanitization
  "dotenv": "^16.3.1" // Environment management
}
```

### Key Features

| Feature                | Purpose                   | Protection                            |
| ---------------------- | ------------------------- | ------------------------------------- |
| **Helmet.js**          | Security headers          | XSS, Clickjacking, MIME type sniffing |
| **Rate Limiting**      | Request throttling        | Brute force, DDoS attacks             |
| **Input Sanitization** | Payload cleaning          | NoSQL/SQL injection, XSS              |
| **Payload Limits**     | Request size restriction  | Request bomb attacks                  |
| **Structured Logging** | Audit trail               | Compliance, incident investigation    |
| **Error Handling**     | Safe error messages       | Information disclosure prevention     |
| **Graceful Shutdown**  | Clean process termination | Data integrity, connection draining   |

## 🏗️ Infrastructure Security - Infracost Recommendation

### Problem Addressed

❌ **Before:** EC2 instance had public IP - exposed to internet attacks  
✅ **After:** Private subnet with NAT Gateway - secure outbound-only connectivity

### Network Architecture

```
Internet
   ↓
[Internet Gateway]
   ↓
[NAT Gateway] ← Elastic IP (203.x.x.x)
   ↓
[EC2 Instance - Private] ← No public IP
   ↓
Application (Port 3000)
```

### Security Implementation

#### 1. VPC & Subnets

- **VPC CIDR:** 10.0.0.0/16
- **Private Subnet:** 10.0.1.0/24 (EC2 instance)
- **Public Subnet:** 10.0.2.0/24 (NAT Gateway)

#### 2. NAT Gateway

- Provides secure outbound internet access
- All outbound traffic appears from single Elastic IP
- **Cost-effective** alternative to bastion hosts
- Infracost recommendation: ✅ IMPLEMENTED

#### 3. Security Groups

```hcl
# Application SG
Ingress: port 3000 from VPC (10.0.0.0/16)
Egress:  All (0.0.0.0/0)

# Bastion SG (optional)
Ingress: port 22 SSH from your IP (CHANGE IN PRODUCTION!)
Egress:  All (0.0.0.0/0)
```

#### 4. Instance Hardening

- ✅ EBS encryption enabled
- ✅ Automatic security updates
- ✅ Fail2ban SSH protection
- ✅ Unnecessary services disabled
- ✅ Ubuntu 22.04 LTS

## 🚀 Quick Start

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Secrets (GitHub Actions)

This project uses GitHub Actions Secrets for configuration management. See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for complete setup.

**Quick Setup:**

1. Go to GitHub Repository Settings > Secrets and variables > Actions
2. Click "New repository secret"
3. Add secrets like `PORT`, `NODE_ENV`, `AWS_REGION`, etc.

### 3. Run Application

```bash
# Local development (set env vars directly)
PORT=3000 NODE_ENV=development npm run dev

# Production
npm start
```

### 4. Test Security Features

#### Health Check

```bash
curl http://localhost:3000/health
```

#### Rate Limiting Test

```bash
# Make more than 100 requests in 15 minutes
for i in {1..110}; do curl http://localhost:3000/; done
# After 100: Should see rate limit error
```

#### Check Security Headers

```bash
curl -i http://localhost:3000/
# Should see Helmet headers:
# X-Content-Type-Options: nosniff
# X-Frame-Options: DENY
# Strict-Transport-Security: max-age=...
```

## 🏗️ Terraform Deployment

### 1. Prepare Terraform

```bash
cd terraform/
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars - IMPORTANT: Set your key_pair_name
```

### 2. Initialize

```bash
terraform init
```

### 3. Review Plan

```bash
terraform plan
# Verify all resources, especially:
# - NAT Gateway creation
# - EC2 instance in private subnet (no public IP)
# - Security groups
```

### 4. Apply

```bash
terraform apply
# Review and confirm
```

### 5. Access Instance

Option A - AWS Systems Manager (Recommended, no SSH keys):

```bash
aws ssm start-session --target i-xxxxxxxxxxxxx
```

Option B - Bastion Host (add to public subnet):

```bash
ssh -i key.pem -J ubuntu@bastion-ip ubuntu@10.0.1.x
```

Option C - Create ALB (for production):

```bash
# Add Application Load Balancer to terraform/
# Route traffic to EC2 private IP on port 3000
```

## 📊 Cost Analysis

| Component                 | Cost/Month | Notes                       |
| ------------------------- | ---------- | --------------------------- |
| t4g.micro EC2             | ~$3.35     | ARM-based, cost-effective   |
| NAT Gateway               | ~$32.00    | Per gateway (1 recommended) |
| NAT Gateway Data Transfer | ~$0.045/GB | Only count outbound data    |
| EBS (20GB gp3)            | ~$1.60     | Encrypted                   |
| **Total Baseline**        | ~$37       | Plus data transfer          |

### Cost Comparison

- **Bastion Host Alternative:** +$5-10/month for additional EC2 instance + management overhead
- **Public IP + Security Groups:** Higher risk, harder to manage
- **NAT Gateway Solution:** ✅ Best for security + cost

## 🔍 Monitoring & Operations

### Check NAT Gateway Health

```bash
aws ec2 describe-nat-gateways --region us-east-1
# Check: State = "available", BytesOutToDestination metric
```

### Monitor Application

```bash
# On the instance:
tail -f /var/log/syslog | grep swiftpay
# Or use CloudWatch if configured
```

### Check Security Group Rules

```bash
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

## 🔐 Production Recommendations

### Tier 1 (Must Have)

- [ ] Use private subnets with NAT Gateway (✅ Done)
- [ ] Enable EBS encryption (✅ Done)
- [ ] Enable automatic OS updates (✅ Done)
- [ ] Configure rate limiting (✅ Done)
- [ ] Add security headers (✅ Done)

### Tier 2 (Highly Recommended)

- [ ] Add Application Load Balancer
- [ ] Enable HTTPS with ACM certificate
- [ ] Set up CloudWatch monitoring
- [ ] Enable VPC Flow Logs
- [ ] Configure CloudTrail logging
- [ ] Add WAF rules to ALB

### Tier 3 (Enterprise)

- [ ] Multi-AZ NAT Gateways
- [ ] VPN for on-premises access
- [ ] Secrets Manager for credentials
- [ ] Systems Manager Session Manager
- [ ] Advanced threat detection
- [ ] Regular security audits

## 📝 File Changes Summary

### Application Files

- `src/app.js` - Added security middleware, logging, rate limiting
- `src/logger.js` - New: Structured logging utility
- `package.json` - Added security dependencies and scripts (removed dotenv)
- `.env.example` - Updated: GitHub Actions Secrets configuration guide

### Infrastructure Files

- `terraform/main.tf` - Complete rewrite with VPC, NAT, security groups
- `terraform/variables.tf` - New variables for networking and security
- `terraform/output.tf` - Updated outputs (removed public IP reference)
- `terraform/terraform.tfvars.example` - New: Configuration template

### GitHub Actions & Deployment

- `.github/workflows/deploy-example.yml` - Example workflow showing secret injection
- `GITHUB_ACTIONS_SETUP.md` - New: Complete GitHub Actions Secrets setup guide

### Documentation

- `SECURITY.md` - Comprehensive security guide
- `README.md` - Updated with new architecture

## 🚨 Important Notes

1. **Change Bastion Security Group CIDR**
   - Current: `0.0.0.0/0` (open to world)
   - Production: Set to your office/VPN IP range

2. **Key Pair Security**
   - Store EC2 key pair securely
   - Never commit to git
   - Rotate regularly

3. **GitHub Actions Secrets**
   - Configure all sensitive data in GitHub repository secrets
   - Secrets are encrypted and audited
   - See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md) for setup

4. **Environment Variables**
   - Use GitHub Actions Secrets for all deployments
   - For local development, set via command line: `PORT=3000 NODE_ENV=development npm start`
   - No .env files needed

5. **Regular Updates**
   - Keep Node.js updated
   - Update npm packages regularly
   - Monitor security advisories

## 📞 Troubleshooting

### Instance can't reach internet

```bash
# Check NAT Gateway
aws ec2 describe-nat-gateways --filter Name=vpc-id,Values=vpc-xxxxx

# Check route table
aws ec2 describe-route-tables --filters Name=vpc-id,Values=vpc-xxxxx
```

### Can't access application

```bash
# From another instance in same VPC:
curl http://10.0.1.x:3000/health

# Check security group
aws ec2 describe-security-groups --group-ids sg-xxxxx
```

### High NAT Gateway costs

```bash
# Check data usage
aws cloudwatch get-metric-statistics \
  --namespace AWS/NatGateway \
  --metric-name BytesOutToDestination \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-31T00:00:00Z \
  --period 3600 \
  --statistics Sum
```

## 🎯 Next Steps

1. ✅ Deploy infrastructure: `terraform apply`
2. ✅ Install npm dependencies: `npm install`
3. ✅ Configure GitHub Actions Secrets: See [GITHUB_ACTIONS_SETUP.md](GITHUB_ACTIONS_SETUP.md)
4. ✅ Test application: `npm run dev`
5. ✅ Deploy to EC2: Copy app and run
6. 🔄 Add ALB for production access
7. 🔄 Enable CloudWatch monitoring
8. 🔄 Set up automated backups

## 📚 References

- [Helmet.js Documentation](https://helmetjs.github.io/)
- [Express Rate Limit](https://github.com/nfriedly/express-rate-limit)
- [AWS VPC Best Practices](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Security.html)
- [NAT Gateway Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)

---

**Security is an ongoing process. Review and update this implementation regularly.**
