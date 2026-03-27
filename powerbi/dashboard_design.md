# Power BI Dashboard Design
## Traffic Sources & Ad ROI Analysis

---

## Connect to BigQuery

1. Power BI Desktop → **Get Data → Google BigQuery**
2. Project: `your-gcp-project-id`
3. Dataset: `traffic_ad_roi`
4. Load the following Views (do **not** load raw tables directly):
   - `v_channel_performance`
   - `v_monthly_channel_trend`
   - `v_device_channel_conversion`
   - `v_ctr_bucket_analysis`
   - `v_campaign_ctr_cvr_scatter`
   - `v_campaign_roi`
   - `v_monthly_roi_trend`
   - `v_campaign_type_roi`

---

## Report Structure (3 Report Pages)

### Page 1 — Channel Overview

**Goal**: See at a glance which channels create the most value.

| Section | Visual Type | Data Source | Fields |
|--------|-------------|-------------|--------|
| KPI Cards (top) | Card × 5 | v_channel_performance | total_orders, total_revenue_usd, total_spend_usd, avg_ctr (paid), avg conversion_rate |
| Channel order ranking | Clustered Bar | v_channel_performance | channel vs total_orders |
| Channel revenue vs spend | Clustered Column | v_channel_performance | channel vs total_revenue_usd + total_spend_usd |
| ROAS bar | Bar Chart | v_channel_performance | channel vs roas (exclude 0) |
| Monthly trend line | Line Chart | v_monthly_channel_trend | year_month vs revenue_usd, channel as Legend |
| Device distribution | Donut | v_device_channel_conversion | device vs orders |

**Slicers**: channel (multi-select)

---

### Page 2 — CTR vs Conversion

**Goal**: Validate the relationship between CTR and conversion rate.

| Section | Visual Type | Data Source | Fields |
|--------|-------------|-------------|--------|
| CTR × CVR scatter plot | Scatter Chart | v_campaign_ctr_cvr_scatter | X = avg_ctr, Y = avg_session_cvr, Size = total_orders, Color = channel |
| Campaign detail table | Table | v_campaign_ctr_cvr_scatter | campaign_name, channel, avg_ctr, avg_session_cvr, total_orders |
| CTR × CVR combo chart | Line and Clustered Column Chart | v_campaign_daily_ctr_cvr | x = date, y1 = avg_ctr, y2 = avg_session_cvr |
| CTR bucket combo chart | Line and Clustered Column Chart | v_ctr_bucket_analysis | ctr_bucket vs total_revenue_usd vs avg_session_cvr |

**Slicers**: channel, campaign_type

**DAX Measures**:
```dax
Correlation Label = 
VAR avgCTR = AVERAGE(v_campaign_ctr_cvr_scatter[avg_ctr])
VAR avgCVR = AVERAGE(v_campaign_ctr_cvr_scatter[avg_session_cvr])
RETURN "Avg CTR: " & FORMAT(avgCTR, "0.00") & "% | Avg CVR: " & FORMAT(avgCVR, "0.00") & "%"
```

---

### Page 3 — ROI Analysis

**Goal**: Identify the most efficient campaigns.

| Section | Visual Type | Data Source | Fields |
|--------|-------------|-------------|--------|
| KPI Cards | Card × 4 | v_campaign_roi | Best ROAS campaign, Avg ROI%, Total Revenue, Total Spend |
| Campaign ROI ranking | Horizontal Bar | v_campaign_roi | campaign_name vs roi (conditional formatting: negative in red) |
| ROAS vs Spend scatter | Scatter | v_campaign_roi | X = total_spend_usd, Y = roas, Size = total_orders, Color = channel |
| Campaign Type comparison | Matrix | v_campaign_type_roi | channel × campaign_type vs avg_roi, avg_cpa_usd |
| Monthly ROI trend | Line Chart | v_monthly_roi_trend | year_month vs roi, channel as Legend |
| CPA comparison | Bar | v_campaign_roi | campaign_name vs cost_per_acquisition |

**Slicers**: channel, campaign_type, roi (> 0 filter toggle)

**DAX Measures**:
```dax
ROAS Display = 
IF(
    SELECTEDVALUE(v_campaign_roi[total_spend_usd]) = 0,
    "N/A (No Spend)",
    FORMAT(SELECTEDVALUE(v_campaign_roi[roas]), "0.00") & "x"
)

ROI Traffic Light = 
VAR roi = SELECTEDVALUE(v_campaign_roi[roi])
RETURN
    IF(roi >= 100, "🟢 High",
    IF(roi >= 0,   "🟡 Positive",
                   "🔴 Negative"))
```

---

## Design Guidelines

### Color Palette

| Channel | Color Code |
|---------|------------|
| Google Ads   | #4285F4 |
| Facebook Ads | #1877F2 → use #0D47A1 instead (to avoid confusion with Google) |
| Email        | #FF6D00 |
| Organic      | #2E7D32 |
| Direct       | #6A1B9A |

### Global Settings

- Background: `#F8F9FA` (light grey-white)
- Title font: Segoe UI Semibold 18px
- Numeric font: Segoe UI 14px
- KPI Card layout: large number + descriptive subtitle
- All currency: USD `$` format with thousands separator
- All percentages: `0.00%` format

### Conditional Formatting Rules

- ROI% < 0: red background
- ROI% 0–100%: yellow background
- ROI% > 100%: green background
- ROAS < 1: red font