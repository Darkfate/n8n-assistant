# Home Assistant Voice Assistant Setup

This guide covers integrating the n8n AI Agent with Home Assistant's Voice Assistant for natural language smart home control.

---

## Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Voice Command  │────▶│   Home          │────▶│      n8n        │
│  (User speaks)  │     │   Assistant     │     │   AI Agent      │
└─────────────────┘     │   (STT + n8n)   │     │  (GLM 4.7)      │
                        └────────┬────────┘     └────────┬────────┘
                                 │                       │
                                 ▼                       ▼
                        ┌─────────────────┐     ┌─────────────────┐
                        │   n8n Response  │────▶│   Home          │
                        │   (TTS text)    │     │   Assistant     │
                        └─────────────────┘     │   (TTS Output)   │
                                                └─────────────────┘
```

---

## Method 1: Using `conversation` Agent with REST Command (Recommended)

Home Assistant's built-in conversation agent can be configured to use a custom webhook endpoint.

### Step 1: Create n8n Webhook Integration in HA

Add to your `configuration.yaml` or via UI:

```yaml
# configuration.yaml
rest_command:
  n8n_ai_agent:
    url: "http://your-n8n-instance:5678/webhook/ha-agent"
    method: POST
    content_type: "application/json"
    payload: '{"input_text": "{{ text }}", "source": "home-assistant", "request_id": "{{ request_id }}"}'
    verify_ssl: false
```

### Step 2: Create a Script for Voice Command Processing

Create `scripts/ai_voice_assistant.yaml`:

```yaml
# scripts/ai_voice_assistant.yaml
ai_voice_process:
  alias: "AI Voice Process"
  fields:
    text:
      description: "The text to process"
      example: "Turn on living room lights"
  sequence:
    - service: rest_command.n8n_ai_agent
      data:
        text: "{{ text }}"
        request_id: "{{ this.attributes.id | default('manual-' ~ now().timestamp()) }}"
      response_variable:
        n8n_response: "response"
    - service: script.turn_on
      target:
        entity_id: script.ai_voice_response
      data:
        variables:
          response_text: "{{ n8n_response.json.message }}"
          status: "{{ n8n_response.json.status }}"
```

### Step 3: Create Response Handler Script

```yaml
# scripts/ai_voice_response.yaml
ai_voice_response:
  alias: "AI Voice Response"
  fields:
    response_text:
      description: "The response text from n8n"
      example: "Turning on the living room lights"
    status:
      description: "Status (success/error)"
      example: "success"
  sequence:
    - choose:
        - conditions:
            - condition: template
              value_template: "{{ status == 'success' }}"
          sequence:
            - service: tts.google_translate_say
              target:
                entity_id: media_player.your_speaker
              data:
                message: "{{ response_text }}"
      default:
        - service: tts.google_translate_say
          target:
            entity_id: media_player.your_speaker
          data:
            message: "Sorry, {{ response_text }}"
```

### Step 4: Create Custom Voice Pipeline

Create `pipelines/ai_agent_pipeline.yaml`:

```yaml
# pipelines/ai_agent_pipeline.yaml
language: en
stages:
  - stt:
      engine: google
  - conversation:
      conversation_id: ai_agent_conversation
  - tts:
      engine: google
```

---

## Method 2: Using Automation with Voice Trigger

For more control, use automations to trigger on voice assistant finished events.

### Step 1: Create Automation

```yaml
# automations/ai_voice_agent.yaml
- alias: "Voice Assistant - Process with n8n AI"
  id: "voice_assistant_n8n_ai"
  trigger:
    - platform: event
      event_type: voice_assistant_finished
      event_data:
        runner: {}
  action:
    - variables:
        transcript: "{{ trigger.event.data.data.final_transcript }}"
        request_id: "{{ trigger.event.data.data.runner.id }}"
    - service: rest_command.n8n_ai_agent
      data:
        text: "{{ transcript }}"
        request_id: "{{ request_id }}"
      response_variable:
        n8n_response: "response"
    - choose:
        - conditions:
            - condition: template
              value_template: "{{ n8n_response.json.status == 'success' }}"
          sequence:
            - service: notify.mobile_app_your_phone
              data:
                title: "AI Agent"
                message: "{{ n8n_response.json.message }}"
```

---

## Method 3: Custom Intent (Simplest for Basic Use)

Create a custom sentence trigger that calls n8n directly.

```yaml
# sentences.yaml
sentences:
  - Turn on the {name}
  - Turn off the {name}
  - Set temperature to {temp} degrees
  - Activate {scene}
```

```yaml
# intents/ai_agent_intent.yaml
intent_script:
  AIAgentCommand:
    action:
      - service: rest_command.n8n_ai_agent
        data:
          text: "{{ trigger.slots.text }}"
          request_id: "{{ context.id }}"
        response_variable:
          n8n_response: "response"
      - service: tts.google_translate_say
        target:
          entity_id: media_player.your_speaker
        data:
          message: "{{ n8n_response.json.message }}"
```

---

## Environment Variables Configuration

### n8n Credentials

Set these in your n8n instance or Terraform:

| Variable | Description | Example |
|----------|-------------|---------|
| `HOME_ASSISTANT_URL` | HA base URL | `http://homeassistant.local:8123` |
| `HOME_ASSISTANT_TOKEN` | Long-lived access token | Generate in HA UI |
| `ZAI_GLM_API_KEY` | Zai GLM API key | Your API key |

### Home Assistant Token Generation

1. Go to Home Assistant → User Profile → Long-Lived Access Tokens
2. Create token: "n8n Integration"
3. Copy and use as `HOME_ASSISTANT_TOKEN` or configure in n8n credentials

---

## Network Configuration

### Option A: Local Network

```yaml
# In HA configuration.yaml
rest_command:
  n8n_ai_agent:
    url: "http://n8n.local:5678/webhook/ha-agent"
```

### Option B: Tailscale (Recommended for remote access)

```yaml
# Use Tailscale IP or MagicDNS
rest_command:
  n8n_ai_agent:
    url: "http://n8n.tailnet-name.ts.net:5678/webhook/ha-agent"
```

### Option C: Cloud Tunnel with ngrok

If using ngrok for development:
```yaml
rest_command:
  n8n_ai_agent:
    url: "https://abc123.ngrok.io/webhook/ha-agent"
```

---

## Testing the Integration

### 1. Test the Webhook Directly

```bash
# From a machine with network access to n8n
curl -X POST http://your-n8n-instance:5678/webhook/ha-agent \
  -H "Content-Type: application/json" \
  -d '{
    "input_text": "Turn on the living room lights",
    "source": "home-assistant",
    "request_id": "test-123"
  }'

# Expected response:
# {"status":"success","message":"Turning on the living room lights",...}
```

### 2. Test from Home Assistant

```yaml
# Developer Tools → Services → rest_command.n8n_ai_agent
service: rest_command.n8n_ai_agent
data:
  text: "Set temperature to 22 degrees"
  request_id: "ha-test-001"
```

### 3. Test Voice Pipeline

1. Open Home Assistant app on your phone
2. Tap microphone
3. Say: "Turn on the kitchen lights"
4. Verify action executes and voice response plays

---

## Troubleshooting

### Issue: "Failed to call service"

**Solution:** Verify network connectivity from HA to n8n:
```bash
# From Home Assistant container/host
curl -v http://your-n8n-instance:5678/webhook/ha-agent
```

### Issue: "Invalid response from AI"

**Solution:** Check n8n execution logs and verify:
1. `ZAI_GLM_API_KEY` is set correctly
2. `HOME_ASSISTANT_URL` is accessible
3. Entity context is being fetched

### Issue: No TTS response

**Solution:** Verify TTS engine is configured:
```yaml
# configuration.yaml
tts:
  - platform: google_translate
    language: "en"
```

### Issue: Commands execute but no confirmation

**Solution:** Check the `media_player` entity ID in the response script matches your actual speaker.

---

## Example Voice Commands

| Command | Expected Action | Response |
|---------|----------------|----------|
| "Turn on the living room lights" | `light.turn_on` light.living_room | "Turning on the living room lights" |
| "Turn off all lights" | `light.turn_off` all | "Turning off all lights" |
| "Set temperature to 22 degrees" | `climate.set_temperature` 22°C | "Setting temperature to 22 degrees" |
| "Open the garage door" | `cover.open_cover` cover.garage | "Opening the garage door" |
| "Activate bedtime scene" | `scene.turn_on` scene.bedtime | "Activating bedtime scene" |
| "What's the temperature?" | Query climate state | "Current temperature is 20 degrees" |

---

## Security Considerations

1. **Use HTTPS/Tailscale** for production deployments
2. **Restrict webhook paths** to specific endpoints only
3. **Rotate API keys** periodically
4. **Monitor n8n logs** for suspicious activity
5. **Rate limit** voice commands if needed

---

## Next Steps

- [ ] Test webhook connectivity from HA to n8n
- [ ] Configure REST command in HA
- [ ] Set up TTS response script
- [ ] Test voice commands end-to-end
- [ ] Deploy via Terraform (if not already done)
