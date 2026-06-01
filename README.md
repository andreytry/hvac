# HVAC BOC — Business Operations Center

AI-powered lead intake, qualification, and estimation platform for HVAC service businesses.

## Live System

| Component | Details |
|---|---|
| Phone | +1 (786) 699-8690 (Twilio) |
| Voice Agent | ElevenLabs — Aria (agent_0301kstp9w36en2rs3bsyamg4p1f) |
| Database | Supabase — zkylrolpuwybsksspblj.supabase.co (schema: `hvac`) |
| Dashboard (nginx) | http://5.161.46.138 |
| Dashboard (Docker) | http://5.161.46.138:8080 |
| Push Email | andrewtry002@gmail.com |
| Docs | https://ai-process.atlassian.net/wiki/spaces/~7120206f5c09c7ef3c47469fc00c94248f6f72/pages/2949142/HVAC+BOC |

## Architecture

```
Customer calls +1(786)699-8690
        ↓
ElevenLabs Agent "Aria"
  - Bilingual EN/ES (language locked by first reply)
  - Collects: issue, residential/commercial, name, availability
  - Estimates on request ("preliminary, not binding")
        ↓ save_lead tool — async, fires after goodbye
POST /rpc/hvac_intake_lead
        ↓
Supabase qualify_and_estimate() trigger
  - Fuzzy-matches service → hvac.pricing
  - Computes estimate_low / estimate_high
  - +25% surcharge if urgency = emergency
  - Sets qualification_status: qualified / needs_review / unqualified
        ↓
hvac.leads table
        ↓
React Dashboard (Orders / Pricing / Settings)
```

## Stack

| Layer | Technology |
|---|---|
| Voice AI | ElevenLabs Conversational AI (gpt-4o-mini, voice: Rachel) |
| Telephony | Twilio |
| Database | Supabase PostgreSQL (`hvac` schema) |
| Dashboard | React + Babel (CDN), single HTML file |
| Container | Docker — nginx:alpine |
| IaC | Terraform (Hetzner Cloud) |
| CI/CD | GitHub Actions — deploy on push to `main` |
| Automation | n8n (ai-process.app.n8n.cloud) — SMS intake, pending |
| Infra | Hetzner CPX11, Ashburn VA, 5.161.46.138 |

## Repo Structure

```
dashboard/
  hvac-boc.html       — React + Babel dashboard (single file, no build step)
sql/
  schema.sql          — hvac schema, tables, qualify_and_estimate trigger, RPC wrappers
  seed.sql            — 12 pricing rows + config seed
terraform/
  main.tf             — Hetzner server, firewall, SSH key, deploy provisioner
  variables.tf / outputs.tf / versions.tf / providers.tf
  cloud-init.yml      — installs Docker on first boot
  terraform.tfvars.example
docs/
  architecture.md     — system diagram and data flow
  api.md              — Supabase RPC reference
  agent-prompt.md     — ElevenLabs prompt (EN + ES)
.github/workflows/
  deploy.yml          — CI/CD: rsync + docker compose on push to main
Dockerfile            — nginx:alpine, serves dashboard/hvac-boc.html
docker-compose.yml    — single dashboard service
Taskfile.yml          — dev/deploy shortcuts
```

## Quick Start

### Local development

```bash
task serve:py        # Python HTTP server on :8080 (no npm required)
task serve           # npx serve on :8080
```

### Deploy to Hetzner (first time)

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# fill in hcloud_token and ssh key paths
task tf:init
task tf:apply        # provisions server + deploys Docker container
```

### CI/CD (subsequent deploys)

Push to `main` → GitHub Actions rsync files to server → `docker compose build && up -d`.

Required secret in GitHub repo settings:
- `SSH_PRIVATE_KEY` — private key with access to the server

## Database Schema

Three tables in the `hvac` schema: `config`, `pricing`, `leads`.

Key RPC functions (`POST /rest/v1/rpc/{name}`, requires `apikey` + `Authorization` headers):

| Function | Description |
|---|---|
| `hvac_intake_lead` | Create lead (called by ElevenLabs save_lead tool) |
| `hvac_get_leads` | List all leads |
| `hvac_get_pricing` | List 12 services |
| `hvac_get_config` | List config keys |
| `hvac_update_lead_status` | Set status: `new\|contacted\|scheduled\|won\|lost` |
| `hvac_update_pricing` | Edit service pricing row |
| `hvac_update_config` | Edit config key (e.g. `push_email`) |

## Environment Variables

```env
SUPABASE_URL=https://zkylrolpuwybsksspblj.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
ELEVENLABS_API_KEY=sk_...
ELEVENLABS_AGENT_ID=agent_0301kstp9w36en2rs3bsyamg4p1f
TWILIO_ACCOUNT_SID=...
HETZNER_TOKEN=...
```

## Key Constraints

- `save_lead` tool is `execution_mode: async` — fires after goodbye, not mid-call
- Agent never asks for phone or email — collected automatically by Twilio/ElevenLabs
- Estimates always described as "preliminary, not binding"
- Emergency surcharge (+25%) applied in Supabase trigger, not by the agent

## Pending

- [ ] Switch dashboard from port 8080 to 80 (stop legacy nginx, update docker-compose)
- [ ] SMS intake via n8n — pending n8n quota reset
- [ ] Email notification on qualified lead — pending email API key
