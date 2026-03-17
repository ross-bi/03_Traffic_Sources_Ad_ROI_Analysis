# 03 Traffic Sources & Ad ROI Analysis

> Traffic Source and Advertising Effectiveness Analysis | BigQuery + Power BI 

---

## 📋 Project Overview

This project analyzes traffic sources and advertising ROI for an e-commerce platform. It identifies which channels (Google, Facebook, Email) drive the most conversions, examines the relationship between ad click-through rates and order conversion rates, and evaluates the ROI of different advertising campaigns.

---

## 🎯 Key Business Questions

1. **Which traffic sources** (Google, Facebook, Email) generate the most conversions?
2. **What is the correlation** between ad click-through rate (CTR) and order conversion rate?
3. **Which ad campaigns** deliver the highest ROI (Return on Investment)?

---

## 🛠️ Tech Stack

| Tool | Purpose |
|------|---------|
| **Google BigQuery** | Data warehouse & SQL analysis |
| **Power BI** | Dashboard & visualization |
| **dbt** (optional) | Data transformation layer |
| **Python** | Data generation / scripting |

---

## 📁 Project Structure

```
03_Traffic_Sources_Ad_ROI_Analysis/
├── README.md
├── .gitignore
├── data/
│   └── sample/          # Sample CSV files (non-sensitive)
├── bigquery/
│   └── queries/         # SQL analysis queries
├── dbt/                 # dbt models (if used)
├── powerbi/
│   └── screenshots/     # Dashboard screenshots (.png)
└── docs/
    └── analysis_notes.md
```

---

## 📊 Key Metrics

- **CTR** (Click-Through Rate) — Ad clicks / Ad impressions
- **CVR** (Conversion Rate) — Orders / Sessions
- **CPA** (Cost Per Acquisition) — Ad spend / Conversions
- **ROAS** (Return on Ad Spend) — Revenue / Ad spend
- **ROI** — (Revenue - Cost) / Cost × 100%

---

## 🚀 Status

- [ ] Data source setup (BigQuery)
- [ ] SQL queries for traffic source analysis
- [ ] CTR vs CVR correlation analysis
- [ ] Ad campaign ROI calculation
- [ ] Power BI dashboard
- [ ] Documentation

---

## 🔐 Security Note

GCP Service Account keys (`*.json`) and `.env` files are excluded from version control via `.gitignore`. Never commit credentials to this repository.

## License

This project is licensed under the [MIT License](./LICENSE).