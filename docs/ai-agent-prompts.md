# AI Agent Prompts Documentation

This document contains the prompt templates and examples used by the Home Assistant AI Agent.

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

## Home Assistant Voice Assistant Pipeline Configuration

Add this to your Home Assistant `conversation.yaml` or configure via UI:

```yaml
conversation:
  intents:
    HassTurnOn:
      - Turn on the {name}
    HassTurnOff:
      - Turn off the {name}
    HassClimateSetTemperature:
      - Set temperature to {temperature} degrees
```

### Pipeline Configuration

Create a custom pipeline that calls the n8n webhook:

```yaml
# pipelines/custom_assistant.yaml
language: en
stages:
  - stt:
      engine: google
  - conversation:
      agent:
        type: n8n
        url: http://your-n8n-instance:5678/webhook/ha-agent
  - tts:
      engine: google
```

---

## Testing with curl

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
| `ZAI_GLM_API_KEY` | Zai GLM API authentication key | `your-api-key` |
