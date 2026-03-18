terraform {
  required_version = ">= 1.0"
}

variable "workflow_files" {
  description = "List of workflow JSON file paths to deploy"
  type        = list(string)
}

resource "n8n_workflow" "workflows" {
  for_each = toset(var.workflow_files)

  name  = trimsuffix(basename(each.value), ".json")
  active = false

  # Load workflow content from JSON file
  nodes_json      = jsonencode(jsondecode(file(each.value)).nodes)
  connections_json = jsonencode(jsondecode(file(each.value)).connections)
  settings_json    = jsonencode(jsondecode(file(each.value)).settings)

  # Ignore changes to JSON fields after creation
  # n8n may reformat/normalize JSON differently than jsonencode()
  # The source of truth is the JSON file in the repo
  lifecycle {
    ignore_changes = [nodes_json, connections_json, settings_json]
  }

  # Note: Tags must exist in n8n before they can be assigned
  # tags = ["terraform-managed", "home-lab"]
}

output "deployed_workflows" {
  description = "List of deployed workflow names"
  value       = [for wf in n8n_workflow.workflows : wf.name]
}
