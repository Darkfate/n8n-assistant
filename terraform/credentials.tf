# N8n Credentials Configuration
# Credentials are created from GitHub Secrets to support the AI Agent workflow

# Zai GLM API Credential (HTTP Header Auth)
resource "n8n_credential" "zai_glm_api" {
  name        = "Zai GLM API"
  type        = "httpHeaderAuth"
  # Credential data - using GitHub Secret
  data = {
    name  = "Authorization"
    value = "Bearer ${var.zai_glm_api_key}"
  }
}

# Home Assistant API Credential
resource "n8n_credential" "home_assistant_api" {
  name = "Home Assistant API"
  type = "homeAssistantApi"
  # Credential data - only access token is needed
  data = {
    accessToken = var.home_assistant_token
  }
}
