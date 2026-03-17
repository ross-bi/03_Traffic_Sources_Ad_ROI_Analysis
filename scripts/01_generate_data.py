"""
01_generate_data.py
Generate simulated traffic sources & ad ROI data for BigQuery analysis.
Output: 4 CSV files in ../data/
"""

import pandas as pd
import numpy as np
from faker import Faker
import random
from datetime import datetime, timedelta
import os

fake = Faker()
random.seed(42)
np.random.seed(42)

# ── Config ────────────────────────────────────────────────────────────────────
START_DATE = datetime(2024, 1, 1)
END_DATE   = datetime(2024, 12, 31)
OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
os.makedirs(OUTPUT_DIR, exist_ok=True)

CHANNELS = ["Google Ads", "Facebook Ads", "Email", "Organic", "Direct"]

CAMPAIGNS = [
    # (campaign_id, name, channel, type, daily_budget_usd, start_date, end_date)
    ("C001", "Google_Brand_Search",        "Google Ads",   "Search",      500,  "2024-01-01", "2024-12-31"),
    ("C002", "Google_NonBrand_Search",     "Google Ads",   "Search",      800,  "2024-01-01", "2024-12-31"),
    ("C003", "Google_Shopping_Q1",         "Google Ads",   "Shopping",    600,  "2024-01-01", "2024-03-31"),
    ("C004", "Google_Display_Remarketing", "Google Ads",   "Display",     300,  "2024-03-01", "2024-12-31"),
    ("C005", "Facebook_Awareness",         "Facebook Ads", "Awareness",   400,  "2024-01-01", "2024-06-30"),
    ("C006", "Facebook_Conversion",        "Facebook Ads", "Conversion",  700,  "2024-01-01", "2024-12-31"),
    ("C007", "Facebook_Retargeting",       "Facebook Ads", "Retargeting", 350,  "2024-04-01", "2024-12-31"),
    ("C008", "Email_Newsletter_Monthly",   "Email",        "Newsletter",  50,   "2024-01-01", "2024-12-31"),
    ("C009", "Email_Promo_Flash_Sale",     "Email",        "Promotion",   80,   "2024-02-01", "2024-11-30"),
    ("C010", "Email_Abandoned_Cart",       "Email",        "Automation",  30,   "2024-01-01", "2024-12-31"),
    ("C011", "Organic_SEO",               "Organic",      "SEO",         0,    "2024-01-01", "2024-12-31"),
    ("C012", "Direct_Traffic",            "Direct",       "Direct",      0,    "2024-01-01", "2024-12-31"),
]

# CTR baseline & conversion rate by channel
CHANNEL_PARAMS = {
    "Google Ads":   {"ctr_mean": 0.045, "ctr_std": 0.015, "cvr_mean": 0.035, "cvr_std": 0.010, "avg_order": 95},
    "Facebook Ads": {"ctr_mean": 0.022, "ctr_std": 0.008, "cvr_mean": 0.025, "cvr_std": 0.008, "avg_order": 88},
    "Email":        {"ctr_mean": 0.028, "ctr_std": 0.012, "cvr_mean": 0.055, "cvr_std": 0.015, "avg_order": 102},
    "Organic":      {"ctr_mean": 0.000, "ctr_std": 0.000, "cvr_mean": 0.030, "cvr_std": 0.010, "avg_order": 85},
    "Direct":       {"ctr_mean": 0.000, "ctr_std": 0.000, "cvr_mean": 0.045, "cvr_std": 0.012, "avg_order": 110},
}

CAMPAIGN_TYPE_MODIFIER = {
    "Search":      {"cvr": 1.20, "cpc": 1.8},
    "Shopping":    {"cvr": 1.10, "cpc": 0.9},
    "Display":     {"cvr": 0.70, "cpc": 0.5},
    "Awareness":   {"cvr": 0.60, "cpc": 0.8},
    "Conversion":  {"cvr": 1.30, "cpc": 1.5},
    "Retargeting": {"cvr": 1.50, "cpc": 1.2},
    "Newsletter":  {"cvr": 1.00, "cpc": 0.1},
    "Promotion":   {"cvr": 1.40, "cpc": 0.1},
    "Automation":  {"cvr": 1.60, "cpc": 0.05},
    "SEO":         {"cvr": 1.00, "cpc": 0.0},
    "Direct":      {"cvr": 1.00, "cpc": 0.0},
}

# ── Helper ────────────────────────────────────────────────────────────────────
def random_date(start, end):
    delta = end - start
    return start + timedelta(days=random.randint(0, delta.days))

def date_range(start_str, end_str):
    s = datetime.strptime(start_str, "%Y-%m-%d")
    e = datetime.strptime(end_str,   "%Y-%m-%d")
    return s, e

# ── 1. campaigns ─────────────────────────────────────────────────────────────
print("Generating campaigns...")
campaign_rows = []
for c in CAMPAIGNS:
    campaign_rows.append({
        "campaign_id":    c[0],
        "campaign_name":  c[1],
        "channel":        c[2],
        "campaign_type":  c[3],
        "daily_budget":   c[4],
        "start_date":     c[5],
        "end_date":       c[6],
    })
df_campaigns = pd.DataFrame(campaign_rows)
df_campaigns.to_csv(f"{OUTPUT_DIR}/campaigns.csv", index=False)
print(f"  campaigns: {len(df_campaigns)} rows")

# ── 2. ad_impressions (daily grain per campaign) ──────────────────────────────
print("Generating ad_impressions...")
impression_rows = []
for c in CAMPAIGNS:
    cid, cname, channel, ctype, budget, sd, ed = c
    s, e = date_range(sd, ed)
    params = CHANNEL_PARAMS[channel]
    mod    = CAMPAIGN_TYPE_MODIFIER[ctype]

    current = s
    while current <= e and current <= END_DATE:
        # seasonality: Q4 boost
        month = current.month
        season_mult = 1.3 if month in [11, 12] else (1.1 if month in [3, 4] else 1.0)

        impressions = int(np.random.normal(budget * 12, budget * 3) * season_mult)
        impressions = max(impressions, 50)

        if channel in ["Organic", "Direct"]:
            clicks = 0
            ctr    = 0.0
            spend  = 0.0
        else:
            ctr    = max(0.005, np.random.normal(params["ctr_mean"], params["ctr_std"]))
            clicks = int(impressions * ctr)
            cpc    = max(0.1, np.random.normal(mod["cpc"] * 1.2, 0.3))
            spend  = round(min(clicks * cpc, budget * 1.1), 2)

        impression_rows.append({
            "impression_id":  f"IMP-{cid}-{current.strftime('%Y%m%d')}",
            "campaign_id":    cid,
            "date":           current.strftime("%Y-%m-%d"),
            "impressions":    impressions,
            "clicks":         clicks,
            "ctr":            round(ctr, 6) if channel not in ["Organic", "Direct"] else 0.0,
            "spend_usd":      spend,
        })
        current += timedelta(days=1)

df_impressions = pd.DataFrame(impression_rows)
df_impressions.to_csv(f"{OUTPUT_DIR}/ad_impressions.csv", index=False)
print(f"  ad_impressions: {len(df_impressions)} rows")

# ── 3. sessions ───────────────────────────────────────────────────────────────
print("Generating sessions...")
devices  = ["desktop", "mobile", "tablet"]
dev_wt   = [0.45, 0.45, 0.10]
countries = ["HK", "SG", "TW", "US", "GB", "AU", "JP", "MY"]
country_wt = [0.35, 0.20, 0.15, 0.10, 0.05, 0.05, 0.05, 0.05]

session_rows = []
session_id   = 1

for c in CAMPAIGNS:
    cid, cname, channel, ctype, budget, sd, ed = c
    s, e = date_range(sd, ed)
    params = CHANNEL_PARAMS[channel]
    mod    = CAMPAIGN_TYPE_MODIFIER[ctype]

    # Derive daily sessions from impressions for this campaign
    camp_imp = df_impressions[df_impressions["campaign_id"] == cid].copy()

    for _, row in camp_imp.iterrows():
        date_obj = datetime.strptime(row["date"], "%Y-%m-%d")
        if channel in ["Organic", "Direct"]:
            n_sessions = max(10, int(np.random.normal(budget if budget > 0 else 80, 20)))
        else:
            n_sessions = max(0, int(row["clicks"] * np.random.uniform(0.85, 1.0)))

        for _ in range(n_sessions):
            session_time = date_obj + timedelta(
                hours=random.randint(0, 23),
                minutes=random.randint(0, 59),
                seconds=random.randint(0, 59)
            )
            device  = random.choices(devices, dev_wt)[0]
            country = random.choices(countries, country_wt)[0]
            pages   = max(1, int(np.random.normal(3.5, 1.5)))
            duration = max(10, int(np.random.normal(180, 90)))
            bounced = 1 if pages == 1 and duration < 30 else 0

            session_rows.append({
                "session_id":   f"S{session_id:08d}",
                "campaign_id":  cid,
                "channel":      channel,
                "session_date": session_time.strftime("%Y-%m-%d"),
                "session_ts":   session_time.strftime("%Y-%m-%d %H:%M:%S"),
                "device":       device,
                "country":      country,
                "pages_viewed": pages,
                "session_duration_sec": duration,
                "is_bounce":    bounced,
            })
            session_id += 1

df_sessions = pd.DataFrame(session_rows)
df_sessions.to_csv(f"{OUTPUT_DIR}/sessions.csv", index=False)
print(f"  sessions: {len(df_sessions)} rows")

# ── 4. conversions ────────────────────────────────────────────────────────────
print("Generating conversions...")
order_id = 1
conversion_rows = []

for c in CAMPAIGNS:
    cid, cname, channel, ctype, budget, sd, ed = c
    params = CHANNEL_PARAMS[channel]
    mod    = CAMPAIGN_TYPE_MODIFIER[ctype]

    camp_sessions = df_sessions[df_sessions["campaign_id"] == cid]
    cvr = max(0.005, np.random.normal(
        params["cvr_mean"] * mod["cvr"],
        params["cvr_std"]
    ))

    for _, sess in camp_sessions.iterrows():
        if sess["is_bounce"] == 1:
            continue
        if random.random() > cvr:
            continue

        order_value = max(10, np.random.normal(params["avg_order"], 30))
        conv_ts     = datetime.strptime(sess["session_ts"], "%Y-%m-%d %H:%M:%S")
        conv_ts    += timedelta(minutes=random.randint(2, 25))

        conversion_rows.append({
            "order_id":       f"ORD-{order_id:07d}",
            "session_id":     sess["session_id"],
            "campaign_id":    cid,
            "channel":        channel,
            "order_date":     conv_ts.strftime("%Y-%m-%d"),
            "order_ts":       conv_ts.strftime("%Y-%m-%d %H:%M:%S"),
            "order_value_usd": round(order_value, 2),
            "device":         sess["device"],
            "country":        sess["country"],
        })
        order_id += 1

df_conversions = pd.DataFrame(conversion_rows)
df_conversions.to_csv(f"{OUTPUT_DIR}/conversions.csv", index=False)
print(f"  conversions: {len(df_conversions)} rows")

# ── Summary ───────────────────────────────────────────────────────────────────
print("\n=== Data Generation Complete ===")
print(f"  campaigns:      {len(df_campaigns):,} rows  → data/campaigns.csv")
print(f"  ad_impressions: {len(df_impressions):,} rows  → data/ad_impressions.csv")
print(f"  sessions:       {len(df_sessions):,} rows  → data/sessions.csv")
print(f"  conversions:    {len(df_conversions):,} rows  → data/conversions.csv")
