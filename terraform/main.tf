terraform {
  required_version = ">= 1.0"
  required_providers {
    n8n = {
      source  = "kodflow/n8n"
      version = "1.6.0"
    }
  }

  # State can be backed by GitHub or other backends
  # backend "http" {
  #   lock_url    = "https://github.com/Darkfate/n8n-assistant/terraform.lock"
  #   address     = "https://github.com/Darkfate/n8n-assistant/terraform.tfstate"
  # }
}

provider "n8n" {
  # Base URL for your n8n instance (from N8N_API_URL env var)
  base_url = var.n8n_api_url
  # API key for authentication (from N8N_API_KEY env var)
  api_key  = var.n8n_api_key
}
