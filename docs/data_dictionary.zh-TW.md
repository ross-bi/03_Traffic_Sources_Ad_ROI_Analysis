# 資料字典
## Traffic Sources & Ad ROI Analysis

---

## 一、原始資料表（`traffic_ad_roi.*`）

### Table: `campaigns`

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

### Table: `ad_impressions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| impression_id | STRING | 每日曝光記錄唯一識別碼 | IMP-C001-20240101 |
| campaign_id | STRING | 關聯廣告活動 FK | C001 |
| date | DATE | 記錄日期（Partition Key） | 2024-01-15 |
| impressions | INT64 | 廣告曝光次數 | 6000 |
| clicks | INT64 | 廣告點擊次數 | 270 |
| ctr | FLOAT64 | 點擊率 = clicks / impressions（原始值） | 0.045 |
| spend_usd | FLOAT64 | 當日廣告支出（USD） | 486.00 |

> **注意**：Organic 與 Direct 渠道的 `clicks` / `ctr` / `spend_usd` 均為 0，因為這些渠道無廣告支出。

---

### Table: `sessions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| session_id | STRING | Session 唯一識別碼 | S00000001 |
| campaign_id | STRING | 來源廣告活動 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| session_date | DATE | Session 日期（Partition Key） | 2024-01-15 |
| session_ts | DATETIME | Session 開始時間戳 | 2024-01-15 14:32:11 |
| device | STRING | 裝置類型 | desktop / mobile / tablet |
| country | STRING | 用戶國家代碼（ISO 2碼） | HK / SG / TW / US |
| pages_viewed | INT64 | 瀏覽頁數 | 4 |
| session_duration_sec | INT64 | Session 時長（秒） | 215 |
| is_bounce | INT64 | 是否為跳出 Session（1=是，0=否） | 0 |

---

### Table: `conversions`

| 欄位 | 類型 | 說明 | 範例 |
|------|------|------|------|
| order_id | STRING | 訂單唯一識別碼 | ORD-0000001 |
| session_id | STRING | 關聯 Session FK | S00000001 |
| campaign_id | STRING | 來源廣告活動 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| order_date | DATE | 訂單日期（Partition Key） | 2024-01-15 |
| order_ts | DATETIME | 訂單時間戳 | 2024-01-15 14:45:22 |
| order_value_usd | FLOAT64 | 訂單金額（USD） | 97.50 |
| device | STRING | 下單裝置 | mobile |
| country | STRING | 用戶國家代碼（ISO 2碼） | HK |

---

## 二、清洗後資料表（`traffic_ad_roi_clean.*`）

由 `01_data_cleaning.sql` 生成，以下列出各表相對於原始表**新增或修改**的欄位。

### Table: `campaigns`（cleaned）

| 欄位 | 類型 | 說明 | 異動說明 |
|------|------|------|---------|
| campaign_name | STRING | 廣告活動名稱（標準化） | NULL / 空白補為 `'Unknown'`；套用 `INITCAP` 格式 |
| channel | STRING | 流量渠道（標準化） | 統一大小寫，如 `'GOOGLE'` → `'Google Ads'` |
| campaign_type | STRING | 廣告類型（標準化） | 統一大小寫，如 `'SEARCH'` → `'Search'` |
| daily_budget_usd | FLOAT64 | 每日預算（USD，修正後） | 原欄位重命名；NULL 補 0，負值修正為 0 |
| end_date | DATE | 活動結束日期 | `end_date < start_date` 時設為 NULL |
| **is_active** | BOOLEAN | 是否仍在投放中 | **新增**：`end_date IS NULL OR end_date >= CURRENT_DATE()` |
| **cleaned_at** | TIMESTAMP | ETL 清洗時間戳 | **新增** |

---

### Table: `ad_impressions`（cleaned）

| 欄位 | 類型 | 說明 | 異動說明 |
|------|------|------|---------|
| impressions | INT64 | 廣告曝光次數（修正後） | NULL 補 0，負值修正為 0 |
| clicks | INT64 | 廣告點擊次數（修正後） | NULL 補 0，負值修正為 0 |
| **ctr_calculated** | FLOAT64 | 從原始數值重新計算的 CTR | **新增**：`SAFE_DIVIDE(clicks, impressions)`，impressions=0 時為 0 |
| ctr_original | FLOAT64 | 原始儲存的 CTR 值 | 原 `ctr` 欄位重命名；限縮至 [0,1] 範圍 |
| spend_usd | FLOAT64 | 廣告支出（修正後） | NULL 補 0，負值修正為 0 |
| **cost_per_click_usd** | FLOAT64 | 每次點擊成本（CPC） | **新增**：`SAFE_DIVIDE(spend_usd, clicks)` |
| **cleaned_at** | TIMESTAMP | ETL 清洗時間戳 | **新增** |

---

### Table: `sessions`（cleaned）

| 欄位 | 類型 | 說明 | 異動說明 |
|------|------|------|---------|
| channel | STRING | 流量渠道（標準化） | 統一大小寫格式 |
| device | STRING | 裝置類型（標準化） | 統一首字大寫：`Desktop` / `Mobile` / `Tablet`；其他補 `'Unknown'` |
| country | STRING | 國家代碼（標準化） | `UPPER(TRIM(...))` 統一大寫；NULL 補 `'Unknown'` |
| pages_viewed | INT64 | 瀏覽頁數（修正後） | 最小值限為 1 |
| session_duration_sec | INT64 | Session 時長（修正後） | 負值修正為 0 |
| is_bounce | INT64 | 跳出標記（驗證後） | 非 0/1 值設為 NULL |
| **engagement_tier** | STRING | 互動深度分層 | **新增**：`High`（時長≥180s 且 頁數≥3）/ `Medium`（時長≥60s 且 頁數≥2）/ `Low`（其他） |
| **cleaned_at** | TIMESTAMP | ETL 清洗時間戳 | **新增** |

---

### Table: `conversions`（cleaned）

| 欄位 | 類型 | 說明 | 異動說明 |
|------|------|------|---------|
| channel | STRING | 流量渠道（標準化） | 統一大小寫格式 |
| order_value_usd | FLOAT64 | 訂單金額（驗證後） | ≤ 0 的值設為 NULL；整筆記錄同時被過濾移除 |
| **order_value_tier** | STRING | 訂單金額分層 | **新增**：`High Value`（≥$500）/ `Mid Value`（≥$100）/ `Low Value`（其他）/ `Invalid`（≤0）|
| device | STRING | 下單裝置（標準化） | 統一首字大寫；其他補 `'Unknown'` |
| country | STRING | 國家代碼（標準化） | `UPPER(TRIM(...))` 統一大寫；NULL 補 `'Unknown'` |
| **cleaned_at** | TIMESTAMP | ETL 清洗時間戳 | **新增** |

---

## 三、分析指標定義

| 指標 | 公式 | 說明 |
|------|------|------|
| CTR (Click-Through Rate) | `clicks ÷ impressions` | 廣告點擊率 |
| CVR (Conversion Rate) | `orders ÷ sessions` | Session 轉換率（以 Session 為分母）|
| Click CVR | `orders ÷ clicks` | 點擊到訂單轉換率（以 Clicks 為分母）|
| CPC (Cost Per Click) | `spend ÷ clicks` | 每次點擊成本 |
| CPM (Cost Per Mille) | `spend ÷ impressions × 1,000` | 每千次曝光成本 |
| CPA (Cost Per Acquisition) | `spend ÷ orders` | 每次轉換成本 |
| ROAS (Return on Ad Spend) | `revenue ÷ spend` | 廣告支出回報率（倍數）|
| ROI% | `(revenue − spend) ÷ spend × 100` | 投資報酬率（百分比）|

---

## 四、分析 Views 說明

| View 名稱 | 來源 SQL | 說明 |
|-----------|---------|------|
| `v_channel_performance` | `02_traffic_analysis.sql` | 各渠道整體表現：訂單數、收益、CVR、總支出、ROAS |
| `v_monthly_channel_trend` | `02_traffic_analysis.sql` | 各渠道月度訂單與收益趨勢（2024 全年）|
| `v_device_channel_conversion` | `02_traffic_analysis.sql` | 裝置 × 渠道交叉轉換分布 |
| `v_campaign_daily_ctr_cvr` | `03_ctr_conversion.sql` | 各 Campaign 日級別 CTR 與 CVR 趨勢 |
| `v_ctr_bucket_analysis` | `03_ctr_conversion.sql` | CTR 分桶（<1%、1–2%、…、≥5%）對應的 CVR 分析 |
| `v_campaign_ctr_cvr_scatter` | `03_ctr_conversion.sql` | Campaign 層級散點圖資料（CTR vs CVR，氣泡大小=訂單量）|
| `v_campaign_roi` | `04_roi_analysis.sql` | 各 Campaign 總支出、總收益、ROAS、ROI%、CPA |
| `v_monthly_roi_trend` | `04_roi_analysis.sql` | 月度 ROAS 與 ROI 趨勢 |
| `v_campaign_type_roi` | `04_roi_analysis.sql` | 依 Campaign Type 彙總的 ROI 比較 |
| `dim_channel` | `05_dim_channel.sql` | 渠道維度表（含展示排序）|
| `dim_campaign_type` | `05_dim_channel.sql` | Campaign Type 維度表（含展示排序）|

---

## 五、Data Lineage
```
campaigns (master dimension)
│
├──► ad_impressions (daily grain — paid channels only)
│ │
│ └──► v_campaign_daily_ctr_cvr
│ └──► v_ctr_bucket_analysis
│ └──► v_campaign_ctr_cvr_scatter
│ └──► v_campaign_roi
│
├──► sessions (one row per website visit)
│ │
│ └──► v_channel_performance
│ └──► v_monthly_channel_trend
│ └──► v_device_channel_conversion
│ └──► v_ctr_bucket_analysis
│
└──► conversions (one row per order)
│
└──► v_channel_performance
└──► v_campaign_roi
└──► v_monthly_roi_trend
└──► v_campaign_type_roi
```

---

## 六、模擬參數（Simulation Parameters）

| 渠道 | 基準 CTR | 基準 CVR | 平均客單價 | 適用 Campaign Type |
|------|---------|---------|----------|-------------------|
| Google Ads | 4.5% | 3.5% | $95 | Search / Shopping / Display |
| Facebook Ads | 2.2% | 2.5% | $88 | Awareness / Conversion / Retargeting |
| Email | 2.8% | 5.5% | $102 | Newsletter / Promotion / Automation |
| Organic | N/A | 3.0% | $85 | SEO |
| Direct | N/A | 4.5% | $110 | Direct |

**Campaign Type 修正係數（相對基準 CVR）：**

| Campaign Type | CVR 乘數 | CPC 乘數 | 說明 |
|--------------|---------|---------|------|
| Search | 1.20x | 1.8x | 主動搜尋意圖高，轉換率高於平均 |
| Shopping | 1.10x | 0.9x | 帶有產品圖片，轉換意圖較強 |
| Display | 0.70x | 0.5x | 品牌曝光為主，轉換率較低 |
| Awareness | 0.60x | 0.8x | 純上漏斗，轉換率最低 |
| Conversion | 1.30x | 1.5x | 直接以轉換為目標，效率高 |
| Retargeting | 1.50x | 1.2x | 再行銷受眾轉換意圖強 |
| Newsletter | 1.00x | 0.1x | 訂閱用戶基準轉換率，成本極低 |
| Promotion | 1.40x | 0.1x | 促銷驅動，轉換率高，成本低 |
| Automation | 1.60x | 0.05x | 棄購車觸發，最高轉換率，成本最低 |
| SEO | 1.00x | 0.0x | 無廣告支出 |
| Direct | 1.00x | 0.0x | 無廣告支出 |

> 所有數值以 `random.seed(42)` 固定，加入季節性乘數（Q4：×1.3；Q1 春季：×1.1；其他：×1.0）。

---

## 七、國家代碼對照

| 代碼 | 國家/地區 | 模擬權重 |
|------|----------|---------|
| HK | 香港 | 35% |
| SG | 新加坡 | 20% |
| TW | 台灣 | 15% |
| US | 美國 | 10% |
| GB | 英國 | 5% |
| AU | 澳洲 | 5% |
| JP | 日本 | 5% |
| MY | 馬來西亞 | 5% |