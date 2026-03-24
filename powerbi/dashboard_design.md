# Power BI Dashboard Design
## Traffic Sources & Ad ROI Analysis

---

## 連接 BigQuery

1. Power BI Desktop → **Get Data → Google BigQuery**
2. Project: `your-gcp-project-id`
3. Dataset: `traffic_ad_roi`
4. 載入以下 Views（不要直接載入原始表）：
   - `v_channel_performance`
   - `v_monthly_channel_trend`
   - `v_device_channel_conversion`
   - `v_ctr_bucket_analysis`
   - `v_campaign_ctr_cvr_scatter`
   - `v_campaign_roi`
   - `v_monthly_roi_trend`
   - `v_campaign_type_roi`

---

## 儀表板結構（3 個 Report Pages）

### Page 1 — Channel Overview（流量來源總覽）

**目標**：一眼看出哪個渠道最有價值

| 區塊 | 視覺化類型 | 資料來源 | 欄位 |
|------|-----------|---------|------|
| KPI Cards（頂部）| Card × 5 | v_channel_performance | total_orders, total_revenue_usd, total_spend_usd, avg_ctr（付費）, avg conversion_rate |
| 渠道轉換量排名 | Clustered Bar | v_channel_performance | channel vs total_orders |
| 渠道收益 vs 支出 | Clustered Column | v_channel_performance | channel vs total_revenue_usd + total_spend_usd |
| ROAS 橫條圖 | Bar Chart | v_channel_performance | channel vs roas（排除 0）|
| 月度趨勢線 | Line Chart | v_monthly_channel_trend | year_month vs revenue_usd，channel = Legend |
| 裝置分布 | Donut | v_device_channel_conversion | device vs orders |

**Slicers**：channel（multi-select）、year_month（date range）

---

### Page 2 — CTR vs Conversion（點擊率與轉換分析）

**目標**：驗證 CTR 與轉換率的相關性

| 區塊 | 視覺化類型 | 資料來源 | 欄位 |
|------|-----------|---------|------|
| CTR Bucket 柱狀圖 | Clustered Column | v_ctr_bucket_analysis | ctr_bucket vs avg_session_cvr_pct |
| CTR × CVR 散點圖 | Scatter Chart | v_campaign_ctr_cvr_scatter | X=avg_ctr_pct, Y=avg_session_cvr_pct, Size=total_orders, Color=channel |
| Campaign 詳細表格 | Table | v_campaign_ctr_cvr_scatter | campaign_name, channel, avg_ctr_pct, avg_session_cvr_pct, total_orders |
| CTR Bucket 收益 | Bar | v_ctr_bucket_analysis | ctr_bucket vs total_revenue_usd |
| CTR × CVR 雙軸折線圖 | Line and Clustered Column Chart 或 Dual-axis Line Chart | v_campaign_daily_ctr_cvr | x=date, y1=avg_ctr_pct, y2=avg_session_cvr_pct |


**Slicers**：channel、campaign_type

**DAX Measures**：
```dax
Correlation Label = 
VAR avgCTR = AVERAGE(v_campaign_ctr_cvr_scatter[avg_ctr_pct])
VAR avgCVR = AVERAGE(v_campaign_ctr_cvr_scatter[avg_session_cvr_pct])
RETURN "Avg CTR: " & FORMAT(avgCTR, "0.00") & "% | Avg CVR: " & FORMAT(avgCVR, "0.00") & "%"
```

---

### Page 3 — ROI Analysis（廣告投資報酬分析）

**目標**：找出最高效的廣告活動

| 區塊 | 視覺化類型 | 資料來源 | 欄位 |
|------|-----------|---------|------|
| KPI Cards | Card × 4 | v_campaign_roi | Best ROAS campaign, Avg ROI%, Total Revenue, Total Spend |
| Campaign ROI 排名 | Horizontal Bar | v_campaign_roi | campaign_name vs roi_pct（條件格式：負值紅色）|
| ROAS vs Spend 散點圖 | Scatter | v_campaign_roi | X=total_spend_usd, Y=roas, Size=total_orders, Color=channel |
| Campaign Type 比較 | Matrix | v_campaign_type_roi | channel × campaign_type vs avg_roi_pct, avg_cpa_usd |
| 月度 ROI 趨勢 | Line Chart | v_monthly_roi_trend | year_month vs roi_pct，channel = Legend |
| CPA 比較 | Bar | v_campaign_roi | campaign_name vs cost_per_acquisition |

**Slicers**：channel、campaign_type、roi_pct（> 0 filter toggle）

**DAX Measures**：
```dax
ROAS Display = 
IF(
    SELECTEDVALUE(v_campaign_roi[total_spend_usd]) = 0,
    "N/A (No Spend)",
    FORMAT(SELECTEDVALUE(v_campaign_roi[roas]), "0.00") & "x"
)

ROI Traffic Light = 
VAR roi = SELECTEDVALUE(v_campaign_roi[roi_pct])
RETURN
    IF(roi >= 100, "🟢 High",
    IF(roi >= 0,   "🟡 Positive",
                   "🔴 Negative"))
```

---

## 設計規範

### 色彩方案
| 渠道 | 色碼 |
|------|------|
| Google Ads   | #4285F4 |
| Facebook Ads | #1877F2 → 改用 #0D47A1（避免與 Google 混淆）|
| Email        | #FF6D00 |
| Organic      | #2E7D32 |
| Direct       | #6A1B9A |

### 全域設定
- 背景：`#F8F9FA`（淺灰白）
- 主標題字型：Segoe UI Semibold 18px
- 數值字型：Segoe UI 14px
- KPI Card 格式：大數字 + 副標題說明
- 所有金額：USD $ 格式，千分位分隔符
- 所有百分比：`0.00%` 格式

### 條件格式化規則
- ROI% < 0：紅色背景
- ROI% 0–100%：黃色背景
- ROI% > 100%：綠色背景
- ROAS < 1：紅色字體
