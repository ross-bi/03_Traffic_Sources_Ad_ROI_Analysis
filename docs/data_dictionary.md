# Data Dictionary
## Traffic Sources & Ad ROI Analysis

---

## Table: `campaigns`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| campaign_id | STRING | 廣告活動唯一識別碼 | C001 |
| campaign_name | STRING | 廣告活動名稱 | Google_Brand_Search |
| channel | STRING | 流量渠道 | Google Ads / Facebook Ads / Email / Organic / Direct |
| campaign_type | STRING | 廣告類型 | Search / Shopping / Display / Awareness / Conversion / Retargeting / Newsletter / Promotion / Automation / SEO / Direct |
| daily_budget | FLOAT64 | 每日預算（USD） | 500.00 |
| start_date | DATE | 活動開始日期 | 2024-01-01 |
| end_date | DATE | 活動結束日期 | 2024-12-31 |

---

## Table: `ad_impressions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| impression_id | STRING | 每日曝光記錄唯一識別碼 | IMP-C001-20240101 |
| campaign_id | STRING | 關聯廣告活動 FK | C001 |
| date | DATE | 記錄日期（Partition Key）| 2024-01-15 |
| impressions | INT64 | 廣告曝光次數 | 6000 |
| clicks | INT64 | 廣告點擊次數 | 270 |
| ctr | FLOAT64 | 點擊率 = clicks / impressions | 0.045 |
| spend_usd | FLOAT64 | 當日廣告支出（USD） | 486.00 |

> **注意**：Organic 與 Direct 渠道的 clicks / ctr / spend 均為 0，因為這些渠道無廣告支出。

---

## Table: `sessions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| session_id | STRING | Session 唯一識別碼 | S00000001 |
| campaign_id | STRING | 來源廣告活動 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| session_date | DATE | Session 日期（Partition Key）| 2024-01-15 |
| session_ts | DATETIME | Session 開始時間戳 | 2024-01-15 14:32:11 |
| device | STRING | 裝置類型 | desktop / mobile / tablet |
| country | STRING | 用戶國家代碼 | HK / SG / TW / US |
| pages_viewed | INT64 | 瀏覽頁數 | 4 |
| session_duration_sec | INT64 | Session 時長（秒） | 215 |
| is_bounce | INT64 | 是否為跳出 Session（1=是, 0=否）| 0 |

---

## Table: `conversions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| order_id | STRING | 訂單唯一識別碼 | ORD-0000001 |
| session_id | STRING | 關聯 Session FK | S00000001 |
| campaign_id | STRING | 來源廣告活動 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| order_date | DATE | 訂單日期（Partition Key）| 2024-01-15 |
| order_ts | DATETIME | 訂單時間戳 | 2024-01-15 14:45:22 |
| order_value_usd | FLOAT64 | 訂單金額（USD） | 97.50 |
| device | STRING | 下單裝置 | mobile |
| country | STRING | 用戶國家代碼 | HK |

---

## Key Metrics Definitions

| 指標 | 公式 | 說明 |
|------|------|------|
| CTR (Click-Through Rate) | clicks ÷ impressions | 廣告點擊率 |
| CVR (Conversion Rate) | orders ÷ sessions | Session 轉換率 |
| Click CVR | orders ÷ clicks | 點擊到訂單轉換率 |
| CPC (Cost Per Click) | spend ÷ clicks | 每次點擊成本 |
| CPM (Cost Per Mille) | spend ÷ impressions × 1000 | 每千次曝光成本 |
| CPA (Cost Per Acquisition) | spend ÷ orders | 每次轉換成本 |
| ROAS (Return on Ad Spend) | revenue ÷ spend | 廣告支出回報率 |
| ROI% | (revenue − spend) ÷ spend × 100 | 投資報酬率（百分比）|

---

## Data Lineage

```
campaigns (master)
    │
    ├──► ad_impressions  (daily grain: paid channels only)
    │         │
    │         └──► v_campaign_daily_ctr_cvr
    │
    ├──► sessions  (one row per website visit)
    │         │
    │         └──► v_channel_performance
    │         └──► v_monthly_channel_trend
    │
    └──► conversions  (one row per order)
              │
              └──► v_campaign_roi
              └──► v_monthly_roi_trend
              └──► v_campaign_type_roi
```

## Simulation Parameters

| 渠道 | 基準 CTR | 基準 CVR | 平均客單價 |
|------|---------|---------|----------|
| Google Ads | 4.5% | 3.5% | $95 |
| Facebook Ads | 2.2% | 2.5% | $88 |
| Email | 2.8% | 5.5% | $102 |
| Organic | N/A | 3.0% | $85 |
| Direct | N/A | 4.5% | $110 |
