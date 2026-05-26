# GitHub Actions Secrets Setup Guide

This project uses **GitHub Actions** for secret management instead of `.env` files.

## How It Works

1. **Store secrets in GitHub** - Repository Settings > Secrets
2. **Reference in workflows** - `${{ secrets.SECRET_NAME }}`
3. **Injected at runtime** - Environment variables passed to application
4. **No .env files needed** - Cleaner, more secure approach

## Setup Steps

### 1. Add Secrets to GitHub Repository

Go to: `https://github.com/YOUR_USERNAME/swiftpay-server/settings/secrets/actions`

Click **"New repository secret"** and add these secrets:

#### Required Secrets

```
Name: EC2_HOST
Value: your-ec2-instance-ip (e.g., 10.0.1.25)

Name: EC2_USER
Value: ubuntu

Name: EC2_KEY
Value: (your EC2 private key - paste entire key including headers)
```

#### Optional Secrets (Application Configuration)

```
Name: PORT
Value: 3000 (or your desired port)

Name: NODE_ENV
Value: production

Name: AWS_REGION
Value: us-east-1

Name: LOG_LEVEL
Value: info
```

#### Custom Application Secrets (if needed)

```
Name: DATABASE_URL
Value: your-database-connection-string

Name: API_KEY
Value: your-api-key

Name: JWT_SECRET
Value: your-jwt-secret
```

### 2. Using Secrets in Your Application

**In GitHub Actions workflow** (`.github/workflows/deploy.yml`):

```yaml
env:
  PORT: ${{ secrets.PORT }}
  NODE_ENV: ${{ secrets.NODE_ENV }}
  DATABASE_URL: ${{ secrets.DATABASE_URL }}
```

**In your Node.js code** (already set up):

```javascript
const port = process.env.PORT || 3000;
const nodeEnv = process.env.NODE_ENV || "development";
const dbUrl = process.env.DATABASE_URL;
```

### 3. Security Best Practices

✅ **DO:**

- Store sensitive data only in GitHub Secrets
- Never commit secrets to the repository
- Rotate secrets regularly
- Use descriptive secret names
- Limit secret access with branch protection rules

❌ **DON'T:**

- Hardcode secrets in code
- Use `.env` files in production
- Log secrets in workflow output
- Share private keys in messages
- Store secrets in environment variables locally

### 4. Workflow Execution

When you push to `main` branch:

1. GitHub Actions workflow triggers
2. Secrets are injected as environment variables
3. Application runs with those variables
4. No .env file needed

## Local Development (Without .env)

For **local development**, you have two options:

### Option A: Set Environment Variables Directly

**Linux/Mac:**

```bash
export PORT=3000
export NODE_ENV=development
npm start
```

**Windows PowerShell:**

```powershell
$env:PORT="3000"
$env:NODE_ENV="development"
npm start
```

### Option B: Use a Local .env File (Not Committed)

If you prefer local .env files for convenience:

1. Create `.env` in project root (ignored by .gitignore)
2. Add variables: `PORT=3000`, `NODE_ENV=development`
3. In your deployment (GitHub Actions), don't reference the local .env - use secrets instead

## Example GitHub Actions Workflow

See [`.github/workflows/deploy-example.yml`](.github/workflows/deploy-example.yml) for a complete example showing:

- Installing dependencies
- Running tests
- Deploying to EC2 with environment variables
- Health check verification

## Accessing Secrets in Workflow

### Read-Only in Workflow

```yaml
env:
  MY_VAR: ${{ secrets.MY_SECRET }}
```

### Mask Secrets in Logs

```yaml
- name: Use secret safely
  run: |
    curl -H "Authorization: Bearer ${{ secrets.API_TOKEN }}" https://api.example.com
```

The API_TOKEN will be masked in logs (shown as `***`).

## Rotating Secrets

1. Go to Repository Settings > Secrets
2. Click the secret you want to update
3. Click "Update"
4. Enter new value
5. Click "Update secret"

New deployments will automatically use the updated secret.

## Troubleshooting

### Secret Not Available in Workflow

- ✓ Check secret name matches exactly (case-sensitive)
- ✓ Ensure syntax is `${{ secrets.SECRET_NAME }}`
- ✓ Verify secret is saved in repository

### Environment Variable Not Showing

- Application must read from `process.env.VARIABLE_NAME`
- Check variable is being passed in workflow `env:` section
- Verify variable name matches in application

### Deployment Failures

```bash
# Test secrets are being passed:
# In workflow, add debug step:
- name: Debug
  run: echo "PORT is $PORT, NODE_ENV is $NODE_ENV"
```

Note: Secrets will be masked as `***` in output.

## Benefits of This Approach

| Feature               | .env Files           | GitHub Actions                |
| --------------------- | -------------------- | ----------------------------- |
| **Security**          | ⚠️ Risk if committed | ✅ Encrypted, audit trail     |
| **Accessibility**     | ✅ Local only        | ✅ Team accessible            |
| **Rotation**          | ❌ Manual per system | ✅ Central, instant           |
| **Audit Trail**       | ❌ None              | ✅ Who changed what           |
| **CI/CD Integration** | ⚠️ Manual setup      | ✅ Built-in                   |
| **Multi-Environment** | ❌ Complex           | ✅ Different secrets per repo |

## More Resources

- [GitHub Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [GitHub Actions Environment Variables](https://docs.github.com/en/actions/learn-github-actions/environment-variables)
- [GitHub Actions Best Practices](https://docs.github.com/en/actions/guides/using-github-cli-in-workflows)

---

**No .env files needed - GitHub Actions manages all your secrets securely!** 🔐
