output "workflows" {
  description = "Deployed n8n workflows"
  value       = module.n8n_workflows
}

output "credentials" {
  description = "Deployed n8n credentials"
  value = {
    zai_glm_api         = n8n_credential.zai_glm_api.name
    home_assistant_api  = n8n_credential.home_assistant_api.name
  }
}
