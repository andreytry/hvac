// HVAC BOC Dashboard — React Component
// Connects directly to Supabase hvac schema via public RPC wrappers
// Usage: render in any React 18 app or use hvac-boc.html (self-contained)

const SUPABASE_URL = "https://zkylrolpuwybsksspblj.supabase.co";
const ANON_KEY     = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpreWxyb2xwdXd5YnNrc3NwYmxqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg5MTgwOTIsImV4cCI6MjA5NDQ5NDA5Mn0.xXfcM2u1FrZZujo-1KNnLGkPSkaoRGkjgk7KreB1TPM";

const rpc = async (fn, p = {}) => {
  const r = await fetch(`${SUPABASE_URL}/rest/v1/rpc/${fn}`, {
    method: "POST",
    headers: { "Content-Type": "application/json", "apikey": ANON_KEY, "Authorization": `Bearer ${ANON_KEY}` },
    body: JSON.stringify(p)
  });
  if (!r.ok) throw new Error(await r.text());
  return r.json();
};

// Three tabs: Orders (leads), Pricing, Settings (config)
// See hvac-boc.html for complete self-contained implementation
export default function HvacDashboard() {
  return <div>See hvac-boc.html for full implementation</div>;
}
