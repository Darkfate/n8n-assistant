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

# Google Sheets OAuth Credentials
variable "google_sheets_client_id" {
  description = "Google OAuth2 Client ID for Sheets API access"
  type        = string
  sensitive   = true
  default     = null
}

variable "google_sheets_client_secret" {
  description = "Google OAuth2 Client Secret for Sheets API access"
  type        = string
  sensitive   = true
  default     = null
}
