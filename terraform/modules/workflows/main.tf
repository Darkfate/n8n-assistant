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

# Create local resources to track file hashes for triggering workflow recreation
resource "local_file" "workflow_hashes" {
  for_each = toset(var.workflow_files)
  content  = sha256file(each.value)
  filename = "${path.module}/.hashes/${trimsuffix(basename(each.value), ".json")}.hash"
}

resource "local_file" "template_hashes" {
  for_each = var.workflow_templates
  content  = "${sha256file(each.value.file)}-${sha256(jsonencode(each.value.vars))}"
  filename = "${path.module}/.hashes/${trimsuffix(basename(each.value.file), ".json.tftpl")}.hash"
}

resource "n8n_workflow" "workflows" {
  for_each = toset(var.workflow_files)

  name  = trimsuffix(basename(each.value), ".json")
  active = false

  # Load workflow content from JSON file
  nodes_json      = jsonencode(jsondecode(file(each.value)).nodes)
  connections_json = jsonencode(jsondecode(file(each.value)).connections)
  settings_json    = jsonencode(jsondecode(file(each.value)).settings)

  # Trigger recreation when workflow file hash changes
  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      local_file.workflow_hashes[each.value].id
    ]
    ignore_changes = [nodes_json, connections_json, settings_json]
  }

  # Note: Tags must exist in n8n before they can be assigned
  # tags = ["terraform-managed", "home-lab"]
}

resource "n8n_workflow" "workflow_templates" {
  for_each = var.workflow_templates

  name  = trimsuffix(basename(each.value.file), ".json.tftpl")
  active = false

  # Load workflow content from template file with variables
  nodes_json      = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).nodes)
  connections_json = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).connections)
  settings_json    = jsonencode(jsondecode(templatefile(each.value.file, each.value.vars)).settings)

  # Trigger recreation when template file or variables change
  lifecycle {
    create_before_destroy = true
    replace_triggered_by = [
      local_file.template_hashes[each.key].id
    ]
    ignore_changes = [nodes_json, connections_json, settings_json]
  }

  # Note: Tags must exist in n8n before they can be assigned
  # tags = ["terraform-managed", "home-lab"]
}

output "deployed_workflows" {
  description = "List of deployed workflow names"
  value       = concat([for wf in n8n_workflow.workflows : wf.name], [for wf in n8n_workflow.workflow_templates : wf.name])
}
