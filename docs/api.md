# API Reference

Base URL: `https://zkylrolpuwybsksspblj.supabase.co/rest/v1/rpc/{function}`

## Headers

```
Content-Type:  application/json
apikey:        <SUPABASE_ANON_KEY>
Authorization: Bearer <SUPABASE_ANON_KEY>
```

## Functions

### hvac_intake_lead — create a lead
```json
POST /rpc/hvac_intake_lead
{
  "p_contact_name":     "Jane Doe",
  "p_phone":            "+13055551234",
  "p_email":            "jane@example.com",
  "p_service":          "AC_REPAIR",
  "p_description":      "AC not cooling",
  "p_urgency":          "emergency",
  "p_property_type":    "residential",
  "p_system_age_years": 8,
  "p_source":           "voice"
}
```
Returns: full `hvac.leads` row with computed qualification + estimate.

### hvac_get_leads — list all leads
```json
POST /rpc/hvac_get_leads {}
```
Returns: array of leads ordered by `created_at DESC`.

### hvac_get_pricing — list all services
```json
POST /rpc/hvac_get_pricing {}
```
Returns: array of 12 pricing rows ordered by category.

### hvac_get_config — list all config
```json
POST /rpc/hvac_get_config {}
```

### hvac_update_lead_status
```json
POST /rpc/hvac_update_lead_status
{ "p_id": 1, "p_status": "contacted" }
```
Status values: `new | contacted | scheduled | won | lost`

### hvac_update_pricing
```json
POST /rpc/hvac_update_pricing
{ "p_id": 1, "p_price_min": 175, "p_price_max": 700,
  "p_service_name": "AC Repair", "p_category": "cooling",
  "p_unit": "flat", "p_active": true, "p_notes": null }
```

### hvac_update_config
```json
POST /rpc/hvac_update_config
{ "p_key": "push_email", "p_value": "new@email.com" }
```
