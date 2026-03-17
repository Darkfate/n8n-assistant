# GitHub Actions Deployment Guide

This project uses GitHub Actions to deploy n8n workflows via Terraform, using Tailscale to connect to your n8n instance.

## Prerequisites

### S3 Backend Setup

This project uses an S3-compatible backend for Terraform state storage (MinIO, AWS S3, or any S3-compatible service). Before deploying, ensure:

1. **S3 service is running** (MinIO, AWS S3, or compatible)
2. **Create the terraform-state bucket**:
   - For MinIO: Access the console at your configured endpoint
   - Login with your S3 credentials
   - Create a new bucket named `terraform-state`
   - Set bucket versioning to enabled (optional but recommended)

3. **Initialize Terraform** with backend configuration:
   ```bash
   cd terraform
   terraform init \
     -backend-config="endpoints={s3=\"http://100.67.164.44:9000\"}" \
     -backend-config="access_key=minioadmin" \
     -backend-config="secret_key=your-password" \
     -backend-config="skip_credentials_validation=true" \
     -backend-config="skip_metadata_api_check=true" \
     -backend-config="skip_region_validation=true" \
     -backend-config="skip_requesting_account_id=true" \
     -backend-config="use_path_style=true"
   ```

   **Tip:** Create a shell alias or script for this command to avoid retyping:
   ```bash
   alias tf-init='cd terraform && terraform init \
     -backend-config="endpoints={s3=\"$S3_ENDPOINT\"}" \
     -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
     -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY" \
     -backend-config="skip_credentials_validation=true" \
     -backend-config="skip_metadata_api_check=true" \
     -backend-config="skip_region_validation=true" \
     -backend-config="skip_requesting_account_id=true" \
     -backend-config="use_path_style=true"'
   ```

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

| Secret Name | Description | Example |
|------------|-------------|---------|
| `N8N_API_URL` | Your n8n instance URL (Tailscale address) | `http://n8n.tailnet-name.ts.net` |
| `N8N_API_KEY` | Your n8n API key | `n8n_api_...` |
| `TAILSCALE_AUTH_KEY` | Tailscale auth key for GitHub Actions | `tskey-auth-...` |
| `S3_ENDPOINT` | S3-compatible endpoint URL (configure as Variable) | `http://100.67.164.44:9000` |
| `AWS_ACCESS_KEY_ID` | S3 access key | `minioadmin` |
| `AWS_SECRET_ACCESS_KEY` | S3 secret key | `your-s3-password` |
| `ZAI_GLM_API_KEY` | Zai GLM API key for AI Agent workflow | `your-zai-api-key` |
| `HOME_ASSISTANT_TOKEN` | Long-lived access token for Home Assistant | `eyJhbGci...` |

> **Note:** `S3_ENDPOINT` and `N8N_API_URL` should be configured as **Variables** (not Secrets) in GitHub Actions settings.

### n8n Environment Variables

For the AI Agent workflow to function, you also need to configure the following environment variables in your n8n instance:

| Variable | Description | Example |
|----------|-------------|---------|
| `HOME_ASSISTANT_URL` | Your Home Assistant instance URL | `http://homeassistant.local:8123` |
| `OLLAMA_URL` | Your Ollama instance URL (optional, for Ollama provider) | `http://localhost:11434` |

### Environment Setup

Create a `production` environment in your GitHub repository:

1. Go to `Settings` → `Environments`
2. Click `New environment`
3. Name it `production`
4. Add `N8N_API_URL` as the environment URL (optional)

## Generating Required Keys

### n8n API Key

1. Log in to your n8n instance
2. Go to `Settings` → `API` → `Create API Key`
3. Copy the key and add it to GitHub Secrets

### Tailscale Auth Key

1. Log in to the [Tailscale admin console](https://login.tailscale.com/admin/dns)
2. Go to `Settings` → `Keys`
3. Click `Generate auth key`
4. Check **Reusable** and **Ephemeral** options
5. Optionally set ACL tags for your GitHub Actions nodes
6. Copy the key and add it to GitHub Secrets

### Home Assistant Token

1. Log in to your Home Assistant instance
2. Click your user profile (bottom left)
3. Scroll down to **Long-Lived Access Tokens**
4. Click **Create Token**
5. Name it something recognizable (e.g., "n8n AI Agent")
6. Copy the token and add it to GitHub Secrets as `HOME_ASSISTANT_TOKEN`

### Zai GLM API Key

1. Log in to your [Zai account](https://z.ai)
2. Navigate to API keys or credentials section
3. Generate a new API key
4. Copy the key and add it to GitHub Secrets as `ZAI_GLM_API_KEY`

## Tailscale ACL Configuration

Add the following to your Tailscale ACL to allow GitHub Actions nodes to access your n8n instance:

```json
{
  "tagOwners": {
    "tag:terraform": ["your-email@example.com"]
  },
  "acls": [
    {
      "action": "accept",
      "src": ["tag:terraform"],
      "dst": ["tag:n8n:443", "tag:n8n:5678"]
    }
  ]
}
```

Then update your GitHub Actions auth key to use the tag:
- Regenerate the auth key with the `tag:terraform` tag
- Tag your n8n instance with `tag:n8n`

## Workflow Behavior

### Pull Requests
- Automatically runs `terraform plan`
- Posts plan output as a comment on the PR
- No changes are applied

### Push to Main Branch
- Runs `terraform plan`
- Requires **manual approval** before apply
- After approval, runs `terraform apply`

### Manual Trigger
- Can be triggered from Actions tab
- Same behavior as push to main

## Manual Approval

When a push to `main` triggers the workflow:

1. The `plan` job runs automatically
2. The `apply` job waits for approval
3. Go to `Actions` → Select the workflow run
4. Review the plan output
5. Click `Review deployments` → `Approve`

## Troubleshooting

### Tailscale Connection Issues

```bash
# Test Tailscale auth key locally
tailscale up --authkey=<your-auth-key> --hostname test
```

### n8n API Access

```bash
# Test API access from GitHub Actions runner
curl -H "X-N8N-API-KEY: <your-key>" <N8N_API_URL>/api/v1/workflows
```

### Backend Configuration

The S3 backend requires configuration via `-backend-config` flags (for both local and GitHub Actions).

**For local development**, create a shell alias or script:

```bash
# Add to ~/.bashrc or ~/.zshrc
alias tf-init='cd terraform && terraform init \
  -backend-config="endpoint=http://100.67.164.44:9000" \
  -backend-config="access_key=$AWS_ACCESS_KEY_ID" \
  -backend-config="secret_key=$AWS_SECRET_ACCESS_KEY" \
  -backend-config="skip_credentials_validation=true" \
  -backend-config="skip_metadata_api_check=true" \
  -backend-config="skip_region_validation=true" \
  -backend-config="force_path_style=true"'
```

**For GitHub Actions:**
- Automatically configured via `-backend-config` flags in the workflow
- Requires `S3_ENDPOINT` variable and `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` secrets

**To customize the S3 endpoint:**
Set the `S3_ENDPOINT` environment variable or edit the workflow.

**Common issues:**
- Ensure the `terraform-state` bucket exists in your S3 service
- For S3-compatible services, credentials must be provided explicitly (env vars alone trigger AWS validation)
- Check that the S3 endpoint is accessible from your network
