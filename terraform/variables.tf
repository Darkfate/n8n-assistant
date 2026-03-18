variable "n8n_api_url" {
  description = "The URL of your n8n instance"
  type        = string
  default     = null
}

variable "n8n_api_key" {
  description = "The API key for your n8n instance"
  type        = string
  sensitive   = true
  default     = null
}

# AI Agent Workflow Credentials

variable "zai_glm_api_key" {
  description = "API key for Zai GLM AI service"
  type        = string
  sensitive   = true
  default     = null
}

variable "home_assistant_token" {
  description = "Long-lived access token for Home Assistant API"
  type        = string
  sensitive   = true
  default     = null
}

variable "home_assistant_url" {
  description = "URL of Home Assistant instance"
  type        = string
  default     = null
}
