# GitHub Actions Security Update - Complete Setup Guide

## ✅ Your Current Secrets

You've configured:

- ✅ `AWS_ACCESS_KEY_ID`
- ✅ `AWS_SECRET_ACCESS_KEY`
- ✅ `EC2_KEY_PAIR`
- ✅ `INFRACOST_CLI_AUTHENTICATION_TOKEN`
- ✅ `NODE_ENV`

## 📋 What Else You Need

### Additional Secrets (Recommended)

For a complete setup, consider adding these optional secrets:

```
PORT (optional)
Value: 3000
Description: Application port (can use default)

GITHUB_REPO_NAME (recommended)
Value: Talkird/swiftpay-server
Description: Your GitHub repository URL for automatic deployments
```

**Note:** If your repository is private, you'll need:

```
GITHUB_TOKEN (if private repo)
Value: Your GitHub Personal Access Token with repo access
Description: For cloning private repositories
```

## 🔄 Updated Workflow with Private Subnet Architecture

Your `deploy.yml` has been updated to work with the new security architecture:

### What Changed

1. **Removed public IP dependency**
   - Old: `instance_public_ip` (won't exist now)
   - New: Uses `instance_id` and `instance_private_ip`

2. **Added Systems Manager Session Manager access**
   - Requires IAM role (already added to Terraform)
   - No SSH keys needed for private instance access
   - More secure than SSH from GitHub Actions

3. **Added NODE_ENV environment variable**
   - Application now receives your NODE_ENV secret
   - Can switch between production/development/staging

## 🚀 Terraform Updates Required

Your Terraform has been updated to include:

```hcl
# IAM Role for Systems Manager access
resource "aws_iam_role" "swiftpay_ssm"
resource "aws_iam_instance_profile" "swiftpay"

# EC2 instance now has:
iam_instance_profile = aws_iam_instance_profile.swiftpay.name
```

### Deploy These Terraform Changes

Before your next GitHub Actions deployment:

```bash
cd terraform/
terraform init
terraform plan
# Review changes - should see new IAM role and instance profile
terraform apply
```

## 🔐 How It All Works Together

### Workflow (GitHub Actions)

```
1. Code Push to main branch
    ↓
2. GitHub Actions workflow triggers
    ↓
3. Terraform validates & applies (creates/updates infrastructure)
    ↓
4. Gets EC2 instance ID from Terraform output
    ↓
5. Uses AWS credentials (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY) to authenticate
    ↓
6. Uses Systems Manager Session Manager to connect to private EC2 instance
    ↓
7. Runs deployment script on instance
    ↓
8. Application starts with NODE_ENV secret injected
```

### Security Benefits

| Before (with public IP)         | After (with private subnet)          |
| ------------------------------- | ------------------------------------ |
| ❌ Instance exposed to internet | ✅ Instance only in private subnet   |
| ❌ SSH open to 0.0.0.0/0        | ✅ No public SSH needed              |
| ❌ Direct IP exposure           | ✅ IAM-based access control          |
| ❌ Manual key management        | ✅ Automatic AWS credential rotation |

## 🔧 Deployment Process

### Initial Setup (One-time)

1. **Apply Terraform changes** (includes new IAM role):

   ```bash
   cd terraform/
   terraform apply
   ```

2. **Verify Systems Manager access**:

   ```bash
   # Get instance ID
   INSTANCE_ID=$(terraform output -raw instance_id)

   # Test connection
   aws ssm start-session --target $INSTANCE_ID
   # Should connect to instance shell
   # Type 'exit' to disconnect
   ```

### Automatic Deployments

Once Terraform is deployed:

1. Push code to `main` branch
2. GitHub Actions automatically:
   - Runs Infracost analysis (on PR)
   - Deploys infrastructure (on push to main)
   - Deploys application via Systems Manager (on push to main)
   - Verifies health check

## 📊 Workflow Triggers

### On Pull Request

- Terraform format check
- Terraform validation
- Terraform plan (preview)
- Infracost analysis
- Send cost analysis to Lambda

### On Push to Main

- Terraform apply (deploy infrastructure)
- Deploy application
- Health check verification

## ✨ All Functionalities Preserved

Your workflow maintains:

✅ **Infracost Analysis** - Cost scanning on every PR  
✅ **Terraform Validation** - Infrastructure code quality checks  
✅ **Terraform Plan & Apply** - Infrastructure deployment  
✅ **Application Deployment** - Node.js app deployment  
✅ **Health Checks** - Verify app is running  
✅ **Security Scanning** - Infracost security recommendations

## 🚨 Important Setup Notes

### 1. AWS Credentials Permissions

Your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` should have permissions for:

- EC2 operations (create, modify, describe instances)
- VPC operations (create subnets, security groups, etc.)
- Systems Manager (SSM start-session)
- IAM (role attachment)

**Recommended IAM Policy:**

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "ssm:StartSession",
        "ssm:GetDocument",
        "ssm:DescribeDocument",
        "iam:PassRole",
        "iam:CreateRole",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:DeleteRole",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile"
      ],
      "Resource": "*"
    }
  ]
}
```

### 2. EC2_KEY_PAIR Secret

This is used as backup/for bastion host access. Can keep it for:

- Emergency SSH access if needed
- Bastion host setup (optional)

With private subnet + Systems Manager, it's not used in normal deployments.

### 3. NODE_ENV Secret Values

```
Development: "development"  (logs detailed, errors shown)
Production:  "production"   (logs compact, minimal details)
Staging:     "staging"      (production-like, full features)
```

Currently using whatever value you set for all environments.

## 🔍 Monitoring Deployments

### View Workflow Logs

1. Go to your GitHub repository
2. Click "Actions" tab
3. Click the latest workflow run
4. Expand steps to see deployment logs

### Troubleshoot Systems Manager Connection

```bash
# Check if instance has Systems Manager access
aws ec2 describe-instances \
  --instance-ids $(terraform output -raw instance_id) \
  --query 'Reservations[0].Instances[0].IamInstanceProfile'

# Should return instance profile details, not empty

# Test SSM connection
aws ssm start-session --target $(terraform output -raw instance_id)
```

## 📝 Secrets Checklist

- [x] AWS_ACCESS_KEY_ID
- [x] AWS_SECRET_ACCESS_KEY
- [x] EC2_KEY_PAIR
- [x] INFRACOST_CLI_AUTHENTICATION_TOKEN
- [x] NODE_ENV
- [ ] GITHUB_TOKEN (only if repo is private)
- [ ] PORT (optional, defaults to 3000)

## 🎯 Next Steps

1. **Deploy Terraform changes** (adds IAM role):

   ```bash
   cd terraform/
   terraform plan  # Review changes
   terraform apply
   ```

2. **Test Systems Manager access**:

   ```bash
   aws ssm start-session --target $(terraform output -raw instance_id)
   exit
   ```

3. **Push code to main** and watch GitHub Actions deploy!

4. **Verify app is running**:
   ```bash
   aws ssm start-session --target $(terraform output -raw instance_id)
   curl http://127.0.0.1:3000/health
   exit
   ```

## 💡 Tips & Best Practices

### Local Development

No .env files needed - just set variables:

```bash
NODE_ENV=development PORT=3000 npm run dev
```

### Production Deployment

- Use `NODE_ENV=production` in your secret
- Set `AWS_DEFAULT_REGION` in workflow if different
- Monitor CloudWatch logs (optional)

### Cost Optimization

- NAT Gateway: ~$32/month (covers all outbound traffic)
- t4g.micro: ~$3/month (free tier eligible)
- No additional costs for Systems Manager access

### Security Hardening

- Rotate AWS credentials regularly
- Update EC2 key pair periodically
- Review IAM permissions quarterly
- Enable CloudTrail for audit logs

## ❓ FAQ

**Q: Why Systems Manager instead of SSH?**
A: More secure (IAM-based, no exposed SSH ports), better audit trail, works with private instances.

**Q: Can I still use SSH?**
A: Yes, if you set up a bastion host in the public subnet. Current setup uses Systems Manager.

**Q: What if Systems Manager fails?**
A: Check IAM role is attached to instance, verify AWS credentials have SSM permissions.

**Q: How do I see application logs?**
A: Connect via SSM, then: `tail -f /home/ubuntu/swiftpay-server/src/app.log`

**Q: Can I revert to public IP?**
A: Yes, but not recommended. Change `associate_public_ip_address = true` in terraform/main.tf.

---

**Everything is configured and ready to use!** 🚀
