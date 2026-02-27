terraform {
  required_version = ">= 1.0"
  required_providers {
    n8n = {
      source  = "kodflow/n8n"
      version = "~> 0.1"
    }
  }

  # State can be backed by GitHub or other backends
  # backend "http" {
  #   lock_url    = "https://github.com/Darkfate/n8n-assistant/terraform.lock"
  #   address     = "https://github.com/Darkfate/n8n-assistant/terraform.tfstate"
  # }
}

provider "n8n" {
  # Configuration loaded from environment variables:
  # N8N_API_URL - Your n8n instance URL
  # N8N_API_KEY - Your n8n API key
}
