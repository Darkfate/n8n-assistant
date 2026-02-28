# GitHub Actions Deployment Guide

This project uses GitHub Actions to deploy n8n workflows via Terraform, using Tailscale to connect to your n8n instance.

## Prerequisites

### Required GitHub Secrets

Configure the following secrets in your GitHub repository settings (`Settings` → `Secrets and variables` → `Actions`):

| Secret Name | Description | Example |
|------------|-------------|---------|
| `N8N_API_URL` | Your n8n instance URL (Tailscale address) | `http://n8n.tailnet-name.ts.net` |
| `N8N_API_KEY` | Your n8n API key | `n8n_api_...` |
| `TAILSCALE_AUTH_KEY` | Tailscale auth key for GitHub Actions | `tskey-auth-...` |

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

### State File Issues

If Terraform state issues occur, you may need to configure a backend in `terraform/main.tf`:

```hcl
terraform {
  backend "http" {
    address     = "https://github.com/YOUR_ORG/YOUR_REPO/terraform.tfstate"
    lock_address = "https://github.com/YOUR_ORG/YOUR_REPO/terraform.lock"
  }
}
```
