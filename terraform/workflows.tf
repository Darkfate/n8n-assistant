# N8n Workflows Configuration
# This module references workflow definitions from the workflows/ directory

module "n8n_workflows" {
  source = "./modules/workflows"

  providers = {
    n8n = n8n
  }

  # Workflow definitions are loaded from JSON files in workflows/ (relative to project root)
  workflow_files = [
    "${path.module}/../workflows/home-lab/example.json",
    "${path.module}/../workflows/home-lab/ai-agent.json",
  ]
}
