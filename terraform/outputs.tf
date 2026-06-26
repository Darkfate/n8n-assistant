output "workflows" {
  description = "Deployed n8n workflows"
  value       = module.n8n_workflows
}

output "credentials" {
  description = "Deployed n8n credentials"
  value = {
    google_sheets_oauth2 = n8n_credential.google_sheets_oauth2.name
  }
}

