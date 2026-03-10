# AI Agent Prompts Documentation

This document contains the prompt templates and examples used by the Home Assistant AI Agent.

---

## AI Provider Configuration

The n8n AI Agent workflow supports multiple AI providers through a simple switching mechanism.

### Supported Providers

| Provider | Description | Default Model |
|----------|-------------|---------------|
| **Zai GLM** | Zai's GLM API (cloud) | `glm-4.7` |
| **Ollama** | Local LLM server | `llama3.2` |

### Configuration

Switch between AI providers using environment variables in n8n:

| Variable | Description | Example |
|----------|-------------|---------|
| `AI_PROVIDER` | AI provider to use | `zai-glm` or `ollama` |
| `AI_MODEL` | Model name for the provider | `glm-4.7`, `llama3.2`, `mistral`, etc. |
| `OLLAMA_URL` | Ollama server URL | `http://localhost:11434` (default) |

### Example Configurations

**Zai GLM (default):**
```bash
AI_PROVIDER=zai-glm
AI_MODEL=glm-4.7
```

**Ollama with Llama 3.2:**
```bash
AI_PROVIDER=ollama
AI_MODEL=llama3.2
OLLAMA_URL=http://localhost:11434
```

**Ollama with Mistral:**
```bash
AI_PROVIDER=ollama
AI_MODEL=mistral
OLLAMA_URL=http://ollama.local:11434
```

**Request-level override:**
You can also specify the provider per-request by including `ai_provider` and `ai_model` in the webhook payload:
```json
{
  "input_text": "Turn on the lights",
  "source": "home-assistant",
  "ai_provider": "ollama",
  "ai_model": "llama3.2"
}
```

### Adding a New Provider

To add a new AI provider:

1. **Add a new HTTP Request node** similar to "Call Zai GLM" or "Call Ollama"
2. **Configure the API endpoint** for the new provider
3. **Add a route** in the "Route AI Provider" switch node
4. **Update "Normalize AI Response"** code node to handle the new response format
5. **Connect the new node** to "Merge AI Responses"

---

## System Prompt

```
You are a Home Assistant automation agent. Parse user requests into Home Assistant service calls.

Available entities: {{entities_context}}
Available services: {{services_context}}

Output valid JSON only with this structure:
{
  "action": "call_service" | "query_state" | "error",
  "service": "domain.service",
  "entity_id": "entity.domain",
  "parameters": {},
  "response_text": "natural language confirmation"
}

If request is ambiguous or impossible, set action to "error" with explanation.
```

---

## Few-Shot Examples

### Basic Light Control

**User Input:** "Turn on living room lights"
```json
{
  "action": "call_service",
  "service": "light.turn_on",
  "entity_id": "light.living_room",
  "parameters": {},
  "response_text": "Turning on the living room lights"
}
```

**User Input:** "Turn off all lights"
```json
{
  "action": "call_service",
  "service": "light.turn_off",
  "entity_id": "all",
  "parameters": {},
  "response_text": "Turning off all lights"
}
```

### Climate Control

**User Input:** "Set temperature to 22 degrees"
```json
{
  "action": "call_service",
  "service": "climate.set_temperature",
  "entity_id": "climate.thermostat",
  "parameters": {
    "temperature": 22
  },
  "response_text": "Setting temperature to 22 degrees"
}
```

**User Input:** "Set AC to cool mode"
```json
{
  "action": "call_service",
  "service": "climate.set_hvac_mode",
  "entity_id": "climate.thermostat",
  "parameters": {
    "hvac_mode": "cool"
  },
  "response_text": "Setting AC to cool mode"
}
```

### Cover/Blind Control

**User Input:** "Open the garage door"
```json
{
  "action": "call_service",
  "service": "cover.open_cover",
  "entity_id": "cover.garage_door",
  "parameters": {},
  "response_text": "Opening the garage door"
}
```

**User Input:** "Close all blinds"
```json
{
  "action": "call_service",
  "service": "cover.close_cover",
  "entity_id": "all",
  "parameters": {},
  "response_text": "Closing all blinds"
}
```

### Scenes and Scripts

**User Input:** "Activate bedtime scene"
```json
{
  "action": "call_service",
  "service": "scene.turn_on",
  "entity_id": "scene.bedtime",
  "parameters": {},
  "response_text": "Activating bedtime scene"
}
```

**User Input:** "Run the good morning script"
```json
{
  "action": "call_service",
  "service": "script.turn_on",
  "entity_id": "script.good_morning",
  "parameters": {},
  "response_text": "Running the good morning script"
}
```

### Switches

**User Input:** "Turn on the coffee maker"
```json
{
  "action": "call_service",
  "service": "switch.turn_on",
  "entity_id": "switch.coffee_maker",
  "parameters": {},
  "response_text": "Turning on the coffee maker"
}
```

### Error Cases

**User Input:** "Launch rocket"
```json
{
  "action": "error",
  "response_text": "I don't know how to launch a rocket. Available actions are controlling lights, climate, covers, scripts, and scenes."
}
```

**User Input:** "Make me a sandwich"
```json
{
  "action": "error",
  "response_text": "I can't make sandwiches. I can control your smart home devices like lights, thermostat, and scenes."
}
```

---

## Response Format

The AI must respond with valid JSON containing:

| Field | Type | Description |
|-------|------|-------------|
| `action` | string | One of: `call_service`, `query_state`, `error` |
| `service` | string | The Home Assistant service to call (e.g., `light.turn_on`) |
| `entity_id` | string | The target entity ID or `all` for group operations |
| `parameters` | object | Service-specific parameters |
| `response_text` | string | Natural language confirmation for TTS |

---

## Supported Domains and Services

### Light
- `turn_on` - Turn on light (supports: brightness, color, color_temp)
- `turn_off` - Turn off light
- `toggle` - Toggle light state

### Climate
- `set_temperature` - Set target temperature
- `set_hvac_mode` - Set mode (heat, cool, auto, off)

### Cover
- `open_cover` - Open cover/blind
- `close_cover` - Close cover/blind
- `stop_cover` - Stop moving cover

### Switch
- `turn_on` - Turn on switch
- `turn_off` - Turn off switch
- `toggle` - Toggle switch

### Script
- `turn_on` - Run script
- `reload` - Reload scripts

### Scene
- `turn_on` - Activate scene

### Automation
- `turn_on` - Enable automation
- `turn_off` - Disable automation
- `trigger` - Trigger automation

---

## Home Assistant Voice Assistant Setup

**See [ha-voice-assistant-setup.md](ha-voice-assistant-setup.md) for complete integration instructions.**

The setup guide includes:
- REST command configuration for n8n webhook
- Script creation for voice command processing
- Custom pipeline configuration
- Network and security considerations

### Quick Test

```bash
# Test webhook directly
curl -X POST http://your-n8n-instance:5678/webhook/ha-agent \
  -H "Content-Type: application/json" \
  -d '{
    "input_text": "Turn on the living room lights",
    "source": "home-assistant",
    "request_id": "test-123"
  }'
```

---

## Environment Variables Required

| Variable | Description | Example |
|----------|-------------|---------|
| `HOME_ASSISTANT_URL` | Home Assistant base URL | `http://homeassistant.local:8123` |
| `HOME_ASSISTANT_TOKEN` | Long-lived access token | Generate in HA UI |
| `AI_PROVIDER` | AI provider to use (optional, default: zai-glm) | `zai-glm`, `ollama` |
| `AI_MODEL` | Model name for the provider (optional) | `glm-4.7`, `llama3.2`, `mistral` |
| `OLLAMA_URL` | Ollama server URL (for Ollama provider) | `http://localhost:11434` |
| `ZAI_GLM_API_KEY` | Zai GLM API authentication key | `your-api-key` |
