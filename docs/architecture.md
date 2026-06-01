# Architecture

## System Diagram

```
INBOUND CHANNELS
├── VOICE:  +1 (786) 699-8690 (Twilio)
│   └── ElevenLabs HVAC BOC Agent — "Aria" (South Flow Air)
│       ├── Bilingual EN/ES (auto-detect from first customer reply)
│       ├── Collects: issue, residential/commercial, name, availability
│       ├── Estimates on request: visit ($95–$150) + repair ($150–$400+)
│       └── save_lead tool (async, fires after goodbye)
│           └── POST /rest/v1/rpc/hvac_intake_lead
│
└── SMS:    +1 (786) 699-8690
    └── n8n webhook → hvac_intake_lead (pending quota reset)

SUPABASE — MyScheduler (zkylrolpuwybsksspblj.supabase.co, us-east-1)
├── hvac.config       — key/value system settings
├── hvac.pricing      — 12 services with min/max ranges
├── hvac.leads        — all intake records
└── qualify_and_estimate() trigger (fires on INSERT)
    ├── Matches service_requested → pricing table (fuzzy match)
    ├── Computes estimate_low / estimate_high
    ├── Applies +25% surcharge if urgency = emergency
    ├── Sets qualification_status: qualified / needs_review / unqualified
    └── Stamps push_to_email from config

OUTPUTS
├── Push email → andrewtry002@gmail.com (stamped on lead, send pending)
└── Dashboard → React app, Hetzner 5.161.46.138

INFRASTRUCTURE
├── Hetzner windows-dev-01  178.156.177.203  Windows  (existing dev)
└── Hetzner hvac-ui         5.161.46.138     Ubuntu 24.04  CPX11  (dashboard)
    SSH key: claude-hvac (id: 113028770)
```

## Data Flow — Voice Call

```
1.  Customer dials +1(786)699-8690
2.  Twilio routes to ElevenLabs agent
3.  Aria: "Thank you for calling South Flow Air, this is Aria.
          How can I help you today?
          También hablamos español si lo prefiere."
4.  Language locked by customer first reply (EN or ES, no switching)
5.  Aria collects: issue → home/business → name → availability
6.  If estimate asked → two-part explanation + "preliminary, not binding"
7.  Aria: "...our technician will be in touch shortly. Have a great day!"
8.  save_lead fires async → POST hvac_intake_lead(...)
9.  Supabase trigger: qualify_and_estimate()
10. Lead row created in hvac.leads with all derived fields
```

## ElevenLabs Agent

| Field | Value |
|---|---|
| Agent ID | agent_0301kstp9w36en2rs3bsyamg4p1f |
| Name | South Flow Air — Aria |
| LLM | gpt-4o-mini, temperature 0.2 |
| Voice | Rachel (21m00Tcm4TlvDq8ikWAM) |
| Phone | +1 (786) 699-8690 (phnum_2001ksaf298zf97rgrnxvcgkgtra) |
| Tool | save_lead — execution_mode: async |
| Webhook | POST https://zkylrolpuwybsksspblj.supabase.co/rest/v1/rpc/hvac_intake_lead |
