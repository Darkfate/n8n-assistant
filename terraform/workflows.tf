# N8n Workflows Configuration
# This module references workflow definitions from the workflows/ directory

module "n8n_workflows" {
  source = "./modules/workflows"

  # Workflow definitions are loaded from JSON files in workflows/
  workflow_files = [
    "workflows/home-lab/example.json",
  ]
}
