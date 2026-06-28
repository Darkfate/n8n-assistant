# N8n Credentials Configuration
# Credentials for n8n workflows
# Add new credentials here as needed for your workflows

# Google Sheets OAuth2 Credential
resource "n8n_credential" "google_sheets_oauth2" {
  name = "Google Sheets OAuth2"
  type = "googleSheetsOAuth2Api"

  data = {
    clientId     = var.google_sheets_client_id
    clientSecret = var.google_sheets_client_secret
  }
}
