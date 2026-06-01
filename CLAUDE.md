# HVAC BOC — Claude Code Guide

AI-powered lead intake, qualification, and estimation platform for HVAC service businesses (South Flow Air / aiProcess).

## Live System

| Component | Value |
|---|---|
| Phone | +1 (786) 699-8690 (Twilio) |
| Voice Agent | ElevenLabs — agent_0301kstp9w36en2rs3bsyamg4p1f |
| Database | Supabase — zkylrolpuwybsksspblj.supabase.co (schema: `hvac`) |
| Dashboard (nginx) | http://5.161.46.138 — legacy, served from /var/www/html/index.html |
| Dashboard (Docker) | http://5.161.46.138:8080 — current deploy target |
| Push email | andrewtry002@gmail.com |
| Docs | https://ai-process.atlassian.net/wiki/spaces/~7120206f5c09c7ef3c47469fc00c94248f6f72/pages/2949142/HVAC+BOC |
| GitHub | https://github.com/andrewtry/hvac |

## Architecture

```
Customer → Twilio +1(786)699-8690
               ↓
       ElevenLabs Agent "Aria"
         - Bilingual EN/ES (language locked by first reply)
         - Collects: issue, residential/commercial, name, availability
         - Estimates on request (visit + repair, "preliminary" disclaimer)
               ↓ save_lead tool (async, fires after goodbye)
       POST /rpc/hvac_intake_lead
               ↓
       Supabase qualify_and_estimate() trigger
         - Fuzzy-matches service → hvac.pricing
         - Computes estimate_low / estimate_high
         - +25% surcharge if urgency = emergency
         - Sets qualification_status: qualified / needs_review / unqualified
         - Stamps push_to_email from config
               ↓
       hvac.leads table
               ↓
       React Dashboard (Orders / Pricing / Settings)
```

SMS intake via n8n is pending quota reset and not yet active.

## Repo Structure

```
dashboard/
  hvac-boc.html   — single-file React + Babel dashboard (no build step)
sql/
  schema.sql      — hvac schema, all tables, qualify_and_estimate trigger, 7 RPC wrappers
  seed.sql        — 12 pricing rows + config seed
terraform/
  main.tf         — Hetzner server + firewall + SSH key + deploy null_resource
  cloud-init.yml  — installs Docker on fresh server
  terraform.tfvars.example
docs/
  architecture.md — system diagram, data flow, ElevenLabs agent config
  api.md          — Supabase RPC reference
  agent-prompt.md — ElevenLabs prompt (EN + ES)
.github/workflows/
  deploy.yml      — CI/CD: rsync + docker compose on push to main
Dockerfile        — nginx:alpine, copies hvac-boc.html → index.html
docker-compose.yml — single dashboard service, port 8080:80
Taskfile.yml      — shortcuts: serve, ssh, tf:*, deploy, logs
```

## Stack

- **Voice AI**: ElevenLabs Conversational AI (gpt-4o-mini, temp 0.2, voice: Rachel)
- **Telephony**: Twilio
- **Database**: Supabase PostgreSQL (`hvac` schema)
- **Automation**: n8n (ai-process.app.n8n.cloud) — SMS intake, pending
- **Dashboard**: React + Babel (CDN), single HTML file, no build step
- **Container**: Docker — nginx:alpine
- **IaC**: Terraform (hetznercloud/hcloud provider)
- **CI/CD**: GitHub Actions — push to main → rsync → docker compose up
- **Infra**: Hetzner `hvac-ui` 5.161.46.138, CPX11, Ashburn VA

## Infra Details

- SSH key: `~/.ssh/claude-hvac` (ED25519), chmod 600
- Connect: `ssh -i ~/.ssh/claude-hvac root@5.161.46.138` or `task ssh`
- Hetzner API token: in `terraform/terraform.tfvars` (gitignored)
- Terraform state: local, in `terraform/terraform.tfstate` (gitignored)
- Server has both nginx (port 80, legacy) and Docker container (port 8080, current)
- To switch to Docker on port 80: stop nginx, change docker-compose port to 80:80

## CI/CD

`.github/workflows/deploy.yml` — triggers on push to `main`:
1. Checkout
2. rsync all files (except `.git`, `terraform`, `.claude`, `.idea`) to `/opt/hvac-boc/`
3. SSH: `docker compose build --pull && docker compose up -d --remove-orphans`

Required GitHub secret: `SSH_PRIVATE_KEY` (contents of `~/.ssh/claude-hvac`)

## Database Schema (`hvac` schema)

Three tables: `config`, `pricing`, `leads`.

Key RPC functions (all `POST /rest/v1/rpc/{name}`):
- `hvac_intake_lead` — create lead (called by ElevenLabs save_lead tool)
- `hvac_get_leads` — list all leads
- `hvac_get_pricing` — list 12 services
- `hvac_get_config` — list config keys
- `hvac_update_lead_status` — status: `new|contacted|scheduled|won|lost`
- `hvac_update_pricing` — edit service pricing row
- `hvac_update_config` — edit config key (e.g. `push_email`)

All calls require headers: `apikey` + `Authorization: Bearer <SUPABASE_ANON_KEY>`.

## Environment Variables

```env
SUPABASE_URL=https://zkylrolpuwybsksspblj.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
ELEVENLABS_API_KEY=sk_...
ELEVENLABS_AGENT_ID=agent_0301kstp9w36en2rs3bsyamg4p1f
TWILIO_ACCOUNT_SID=...
HETZNER_TOKEN=...
```

## Pending Work

- [ ] Switch Docker port 8080 → 80 (stop legacy nginx first)
- [ ] SMS intake via n8n — pending n8n quota reset
- [ ] Email notification on qualified lead — pending email API key

## Key Constraints

- The `save_lead` ElevenLabs tool is `execution_mode: async` — fires after goodbye, not mid-call.
- Agent never asks for phone or email (collected by Twilio/ElevenLabs automatically).
- Estimates are always described as "preliminary, not binding" — intentional.
- Emergency surcharge (+25%) is applied inside the Supabase trigger, not by the agent.
- Do not run `terraform apply` without checking `terraform plan` first — imports done but lifecycle rules protect the existing server.
