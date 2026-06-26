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
