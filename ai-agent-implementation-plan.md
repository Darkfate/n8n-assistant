# AI Agent Implementation Plan
## Home Assistant Chat Agent via n8n

---

## Overview

This document outlines the implementation of an AI-powered agent that receives natural language inputs, interprets user intent, and executes actions in Home Assistant via n8n workflows.

### Architecture Diagram

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Input Sources  │     │     n8n         │     │   AI Service    │
│                 │     │                 │     │                 │
│ ┌─────────────┐ │     │ ┌─────────────┐ │     │ ┌─────────────┐ │
│ │Home Asst    │ │────▶│ │  Webhook    │ │────▶│ │  Zai GLM    │ │
│ │Voice        │ │     │ │  (Trigger)  │ │     │ │  4.7        │ │
│ │Assistant    │ │     │ └──────┬──────┘ │     │ └──────┬──────┘ │
│ └─────────────┘ │     │        │         │     │        │       │
│                 │     │        ▼         │     │        ▼       │
│ ┌─────────────┐ │     │ ┌─────────────┐ │     │ ┌─────────────┐ │
│ │MQTT         │ │     │ │  Router/    │ │────▶│ │ Ollama     │ │
│ │(Future)     │ │────▶│ │  Selector   │ │     │ │ (Fallback) │ │
│ └─────────────┘ │     │ └──────┬──────┘ │     │ └─────────────┘ │
│                 │     │        │         │     │                 │
└─────────────────┘     │        ▼         │     └─────────────────┘
                        │ ┌─────────────┐ │
                        │ │  Intent     │ │
                        │ │  Parser     │ │
                        │ └──────┬──────┘ │
                        │        │         │
                        │        ▼         │
                        │ ┌─────────────┐ │     ┌─────────────────┐
                        │ │Home Asst    │ │────▶│  Home Assistant │
                        │ │Node         │ │     │                 │
                        │ └─────────────┘ │     └─────────────────┘
                        └─────────────────┘
```

### High-Level Workflow Flow

1. **Input Reception**: Webhook receives text from Home Assistant Voice Assistant (or future MQTT)
2. **Source Routing**: Identify input source for optional service selection
3. **AI Interpretation**: Send user input + HA entity context to AI service
4. **Intent Parsing**: Parse AI response into structured action (service, entity_id, parameters)
5. **Execution**: Call Home Assistant node with parsed action
6. **Response**: Return result to source (TTS response, confirmation, etc.)

---

## Initial Scope

| Component | Description |
|-----------|-------------|
| **Input Sources** | Home Assistant Voice Assistant (via webhook) |
| **AI Service** | Zai GLM 4.7 (with architecture to easily swap to Ollama/other) |
| **HA Actions** | Broad scope - all entities (lights, climate, covers, scripts, scenes, automations) |
| **Memory/Context** | Stateless - each request is independent |
| **Deployment** | Terraform-managed n8n workflow |

---

## Step-by-Step Implementation Plan

### Phase 1: Core Infrastructure Setup

#### Step 1.1: Create Webhook Trigger
- [ ] Create n8n workflow with Webhook trigger
- [ ] Define webhook path: `/webhook/ha-agent`
- [ ] Configure input schema to receive:
  ```json
  {
    "input_text": "user's natural language request",
    "source": "home-assistant",  // for future routing
    "request_id": "unique-id"     // for tracking responses
  }
  ```

#### Step 1.2: Add AI Service Abstraction Layer
- [ ] Create reusable n8n sub-workflow or function node for AI calls
- [ ] Design AI provider selection logic (switch based on variable)
- [ ] Implement Zai GLM 4.7 integration
- [ ] Prepare placeholder for Ollama/local LLM

**AI Abstraction Interface:**
```javascript
// Input to AI module
{
  "provider": "zai-glm",  // or "ollama", "openai", etc.
  "model": "glm-4.7",
  "system_prompt": "...",
  "user_input": "...",
  "context_data": {...}
}

// Output from AI module
{
  "raw_response": "...",
  "structured_intent": {
    "action": "call_service",
    "service": "light.turn_on",
    "entity_id": "light.living_room",
    "parameters": {"brightness_pct": 80}
  }
}
```

---

### Phase 2: Home Assistant Integration

#### Step 2.1: Set Up Home Assistant Node
- [ ] Configure n8n Home Assistant node credentials
- [ ] Test connection to HA instance
- [ ] Create helper functions to query available entities/services

#### Step 2.2: Build Entity Context Builder
- [ ] Create workflow to fetch HA entity states on demand
- [ ] Build context payload for AI (available entities, their states, attributes)
- [ ] Cache entity list (refresh periodically, not on every request)

**Example Context Structure:**
```json
{
  "available_domains": ["light", "climate", "cover", "script", "scene"],
  "entities": {
    "light.living_room": {"state": "off", "attributes": {"friendly_name": "Living Room"}},
    "climate.thermostat": {"state": "heat", "attributes": {"temperature": 20}}
  },
  "available_services": {
    "light": ["turn_on", "turn_off", "toggle"],
    "climate": ["set_temperature", "set_hvac_mode"]
  }
}
```

---

### Phase 3: AI Prompt Engineering

#### Step 3.1: Design System Prompt
- [ ] Create system prompt defining AI agent role
- [ ] Include HA service/entity context
- [ ] Define output format (structured JSON for actions)

**System Prompt Template:**
```
You are a Home Assistant automation agent. Parse user requests into Home Assistant service calls.

Available entities: {{entities_context}}
Available services: {{services_context}}

Output valid JSON only:
{
  "action": "call_service" | "query_state" | "error",
  "service": "domain.service",
  "entity_id": "entity.domain",
  "parameters": {},
  "response_text": "natural language confirmation"
}

If request is ambiguous or impossible, set action to "error" with explanation.
```

#### Step 3.2: Implement Few-Shot Examples
- [ ] Add examples to prompt covering:
  - Basic controls: "Turn on the lights"
  - Climate: "Set temperature to 22 degrees"
  - Queries: "What's the temperature in the living room?"
  - Scripts/scenes: "Activate movie mode"
  - Error cases: "Launch rocket" (unknown action)

---

### Phase 4: Intent Parsing & Execution

#### Step 4.1: Parse AI Response
- [ ] Add function node to validate JSON response from AI
- [ ] Handle malformed JSON gracefully
- [ ] Extract service, entity_id, and parameters

#### Step 4.2: Execute Home Assistant Action
- [ ] Call HA service node with parsed parameters
- [ ] Handle success/error responses
- [ ] Log all actions for debugging

#### Step 4.3: Response Formatting
- [ ] Format response for Home Assistant Voice Assistant TTS
- [ ] Return structured response:
  ```json
  {
    "status": "success" | "error",
    "message": "I turned on the living room lights",
    "action_taken": "light.turn_on",
    "entity": "light.living_room"
  }
  ```

---

### Phase 5: Home Assistant Voice Assistant Integration

#### Step 5.1: Configure HA Pipeline
- [ ] Create/modify HA voice assistant pipeline
- [ ] Add webhook call to n8n after STT (text-to-speech)
- [ ] Use n8n response for TTS output

#### Step 5.2: End-to-End Testing
- [ ] Test: "Turn on the kitchen lights"
- [ ] Test: "Set thermostat to 21 degrees"
- [ ] Test: "Activate bedtime scene"
- [ ] Test: "What's the status of the garage door?"
- [ ] Test error handling: Unknown entities, ambiguous requests

---

### Phase 6: Terraform Integration

#### Step 6.1: Export Workflow
- [ ] Export completed n8n workflow as JSON
- [ ] Save to `workflows/home-lab/ai-agent.json`

#### Step 6.2: Update Terraform Configuration
- [ ] Add workflow to `terraform/workflows.tf`
- [ ] Test `terraform plan`
- [ ] Deploy via Terraform

---

## Open Questions / Decisions Needed

| Question | Impact | Default/Assumption |
|----------|--------|-------------------|
| What is the Zai GLM 4.7 API endpoint and authentication method? | AI integration | Need API endpoint/docs |
| Should AI select different services based on input source (HA vs MQTT)? | Architecture | No - use same AI for all sources initially |
| How to handle HA instance connectivity (local vs remote)? | Infrastructure | Assume same network via Tailscale |
| Should entity context be sent on every request or cached? | Performance/accuracy | Cache entity list, refresh every 5 min |
| How to handle multiple entity matches (e.g., "turn on lights")? | UX | Ask user for clarification or apply to all |

---

## File Structure After Implementation

```
n8n-assistant/
├── workflows/
│   └── home-lab/
│       ├── ai-agent.json              # Main AI agent workflow
│       └── example.json
├── terraform/
│   ├── workflows.tf                   # Updated with ai-agent.json
│   └── ...
├── docs/
│   └── ai-agent-prompts.md            # Prompt templates and examples
└── ai-agent-implementation-plan.md    # This file
```

---

## Success Criteria

- [ ] Voice command "Turn on the living room lights" successfully executes
- [ ] Voice command "Set temperature to 22 degrees" successfully executes
- [ ] Voice command "Activate bedtime scene" successfully executes
- [ ] Unknown commands return graceful error via TTS
- [ ] AI provider can be changed by updating single variable/credential
- [ ] Workflow is deployed via Terraform
- [ ] Full round-trip latency (voice → action) < 5 seconds
