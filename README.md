# n8n-assistant

Manage n8n workflows for home lab automation using Terraform.

## Overview

This project uses Terraform with the [kodflow/n8n](https://registry.terraform.io/providers/kodflow/n8n) provider to manage n8n workflows as infrastructure-as-code. This approach provides:

- **Version Control**: All workflow definitions tracked in git
- **Declarative Configuration**: Describe desired state, Terraform handles the rest
- **Change Management**: See diffs before applying changes
- **Disaster Recovery**: Quickly restore workflows from version control

## Project Structure

```
n8n-assistant/
├── terraform/
│   ├── main.tf              # Provider configuration
│   ├── variables.tf         # Input variables
│   ├── outputs.tf           # Output values
│   ├── workflows.tf         # Workflow module references
│   └── modules/
│       └── workflows/       # Reusable workflow management module
│           ├── main.tf
│           └── versions.tf
├── workflows/               # n8n workflow definitions (JSON)
│   └── home-lab/
│       └── example.json
├── .gitignore
└── README.md
```

## Getting Started

### Prerequisites

1. **Terraform**: Install [Terraform](https://developer.hashicorp.com/terraform/downloads) >= 1.0
2. **n8n Instance**: A running n8n instance with API access
3. **n8n API Key**: Generate an API key from your n8n settings

### Configuration

Set your n8n credentials as environment variables:

```bash
export N8N_API_URL="https://your-n8n-instance.com"
export N8N_API_KEY="your-api-key-here"
```

Or create a `terraform.tfvars` file (not tracked in git):

```hcl
n8n_api_url = "https://your-n8n-instance.com"
n8n_api_key = "your-api-key-here"
```

### Usage

```bash
# Initialize Terraform
cd terraform
terraform init

# Preview changes
terraform plan

# Apply changes
terraform apply

# Destroy all managed resources
terraform destroy
```

## Adding Workflows

1. Export your workflow from n8n as JSON
2. Place it in the `workflows/` directory
3. Add the file path to `terraform/workflows.tf`

Example:
```hcl
module "n8n_workflows" {
  source = "./modules/workflows"

  workflow_files = [
    "workflows/home-lab/example.json",
    "workflows/home-lab/backup-database.json",
    "workflows/monitoring/alert-slack.json",
  ]
}
```

## Workflow Organization

Organize workflows by domain or purpose:

- `workflows/home-lab/` - Home automation tasks
- `workflows/monitoring/` - Monitoring and alerting
- `workflows/integrations/` - Third-party service integrations
- `workflows/maintenance/` - Scheduled maintenance tasks
