terraform {
  required_version = ">= 1.0"
}

variable "workflow_files" {
  description = "List of workflow JSON file paths to deploy"
  type        = list(string)
}

resource "n8n_workflow" "workflows" {
  for_each = toset(var.workflow_files)

  name        = trimsuffix(basename(each.value), ".json")
  description = "Managed by Terraform - n8n-assistant"
  # Note: The actual workflow content will be loaded from the JSON file
  # You may need to use file() or jsondecode() depending on provider implementation

  tags = ["terraform-managed", "home-lab"]
}

output "deployed_workflows" {
  description = "List of deployed workflow names"
  value       = [for wf in n8n_workflow.workflows : wf.name]
}
