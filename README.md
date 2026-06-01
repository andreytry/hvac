# HVAC BOC — Business Operations Center

AI-powered lead intake, qualification, and estimation platform for HVAC service businesses.

## Live System

| Component | Details |
|---|---|
| Phone | +1 (786) 699-8690 |
| Voice Agent | ElevenLabs — South Flow Air / Aria |
| Agent ID | agent_0301kstp9w36en2rs3bsyamg4p1f |
| Database | Supabase — zkylrolpuwybsksspblj.supabase.co |
| Dashboard | http://5.161.46.138 (Hetzner, nginx) |
| Push Email | andrewtry002@gmail.com |
| Docs | https://ai-process.atlassian.net/wiki/spaces/~7120206f5c09c7ef3c47469fc00c94248f6f72/pages/2949142/HVAC+BOC |

## Architecture

```
Customer calls +1(786)699-8690
        ↓
ElevenLabs HVAC BOC Agent (Aria)
  - Bilingual EN/ES
  - Collects: issue, name, availability
  - Estimates on request (two-part: visit + repair)
        ↓
save_lead tool (mid-call, async)
        ↓
Supabase RPC: hvac_intake_lead()
        ↓
qualify_and_estimate() trigger
  - Matches service → pricing table
  - Computes estimate range
  - Applies 25% emergency surcharge
  - Stamps push_to_email
        ↓
hvac.leads table
        ↓
React Dashboard (Orders / Pricing / Settings)
```

## Stack

- **Voice AI**: ElevenLabs Conversational AI
- **Telephony**: Twilio (+1 786 699-8690)
- **Database**: Supabase (PostgreSQL, hvac schema)
- **Automation**: n8n (ai-process.app.n8n.cloud)
- **Dashboard**: React + Babel, hosted on Hetzner
- **Infra**: Hetzner Cloud (Ashburn VA)
- **Docs**: Confluence (ai-process.atlassian.net)

## Repo Structure

```
/sql
  schema.sql          — full hvac schema, tables, trigger, API wrappers
  seed.sql            — pricing seed data + config
/dashboard
  hvac-boc.jsx        — React dashboard (Orders, Pricing, Settings)
/docs
  architecture.md     — system diagram and data flow
  api.md              — API reference
  agent-prompt.md     — ElevenLabs agent prompt (EN + ES)
```

## Quick Start

### 1. Database
Run `sql/schema.sql` then `sql/seed.sql` on your Supabase project.

### 2. ElevenLabs Agent
- Create agent via API or dashboard
- Set `save_lead` webhook tool → `https://{your-supabase}.supabase.co/rest/v1/rpc/hvac_intake_lead`
- Assign Twilio number to agent

### 3. Dashboard
```bash
# Serve hvac-boc.jsx locally
npx serve dashboard/
# Or deploy to any static host
```

## Environment

```env
SUPABASE_URL=https://zkylrolpuwybsksspblj.supabase.co
SUPABASE_ANON_KEY=eyJhbGci...
ELEVENLABS_API_KEY=sk_...
ELEVENLABS_AGENT_ID=agent_0301kstp9w36en2rs3bsyamg4p1f
TWILIO_ACCOUNT_SID=...
HETZNER_TOKEN=...
```

## Confluence Documentation

Full project docs at:
https://ai-process.atlassian.net/wiki/spaces/~7120206f5c09c7ef3c47469fc00c94248f6f72/pages/2949142/HVAC+BOC

- Analysis — requirements, user stories
- Architecture — diagrams, schema, data flow
- Development — API reference, build log
- QA — 26 test cases, results
- Marketing — Miami GTM, cold call script, pricing tiers
