terraform {
  required_version = ">= 1.0"
}

variable "workflow_files" {
  description = "List of workflow JSON file paths to deploy"
  type        = list(string)
}

variable "workflow_templates" {
  description = "Map of workflow template files and their variables"
  type = map(object({
    file     = string
    vars     = map(string)
  }))
  default  = {}
}

resource "n8n_workflow" "workflows" {
  for_each = toset(var.workflow_files)

  name  = trimsuffix(basename(each.value), ".json")
  active = false

  # Load workflow content from JSON file
  nodes_json      = jsonencode(jsondecode(file(each.value)).nodes)
  connections_json = jsonencode(jsondecode(file(each.value)).connections)
  settings_json    = jsonencode(jsondecode(file(each.value)).settings)
}

resource "n8n_workflow" "workflow_templates" {
  for_each = var.workflow_templates

  name  = trimsuffix(basename(each.value.file), ".json.tftpl")
  active = false

  # Load workflow content from template file with variables
  nodes_json      = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).nodes)
  connections_json = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).connections)
  settings_json    = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).settings)

  # Ignore changes to JSON fields after creation
  lifecycle {
    ignore_changes = [nodes_json, connections_json, settings_json]
  }

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
  value       = concat([for wf in n8n_workflow.workflows : wf.name], [for wf in n8n_workflow.workflow_templates : wf.name])
}
