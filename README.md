# 03 Traffic Sources & Ad ROI Analysis

分析五大流量渠道（Google Ads、Facebook Ads、Email、Organic、Direct）的廣告效益與投資報酬率（ROI）。透過 Python 生成模擬資料，載入 BigQuery 進行 ETL 清洗與多維分析，並以 Power BI 呈現三頁互動式儀表板。

---

## 業務問題

1. **哪些流量來源帶來最多轉換？** — 比較各渠道的訂單量、收益與轉換率
2. **CTR 與 CVR 的關聯性** — 高點擊率是否真的帶來更多訂單？
3. **不同廣告活動的 ROI** — 各 Campaign 的 ROAS 與淨 ROI 排名

---

## 技術架構

| 層級 | 工具 |
|------|------|
| 資料生成 | Python（Pandas、NumPy、Faker） |
| 資料倉儲 | Google BigQuery |
| ETL 清洗 | SQL（BigQuery Standard SQL） |
| 視覺化 | Power BI Desktop |

---

## 資料模型

```
campaigns (12 rows)          ← 廣告活動主檔（C001–C012）
    │
    ├──► ad_impressions (3,720 rows)    ← 每日廣告曝光 & 點擊（付費渠道）
    │
    ├──► sessions (511,797 rows)        ← 網站瀏覽 Session
    │
    └──► conversions (18,288 rows)      ← 訂單轉換事件
```

**12 支廣告活動 × 5 個渠道：**

| Campaign ID | 名稱 | 渠道 | 類型 | 每日預算 |
|-------------|------|------|------|---------|
| C001 | Google_Brand_Search | Google Ads | Search | $500 |
| C002 | Google_Nonbrand_Search | Google Ads | Search | $800 |
| C003 | Google_Shopping_Q1 | Google Ads | Shopping | $600 |
| C004 | Google_Display_Remarketing | Google Ads | Display | $300 |
| C005 | Facebook_Awareness | Facebook Ads | Awareness | $400 |
| C006 | Facebook_Conversion | Facebook Ads | Conversion | $700 |
| C007 | Facebook_Retargeting | Facebook Ads | Retargeting | $350 |
| C008 | Email_Newsletter_Monthly | Email | Newsletter | $50 |
| C009 | Email_Promo_Flash_Sale | Email | Promotion | $80 |
| C010 | Email_Abandoned_Cart | Email | Automation | $30 |
| C011 | Organic_SEO | Organic | SEO | $0 |
| C012 | Direct_Traffic | Direct | Direct | $0 |

---

## 分析 SQL Views

| SQL 檔案 | Views 建立 | 說明 |
|---------|-----------|------|
| `01_data_cleaning.sql` | `traffic_ad_roi_clean.*`（4 tables） | NULL 檢查、去重、欄位標準化、engagement_tier、order_value_tier |
| `02_traffic_analysis.sql` | `v_channel_performance`、`v_monthly_channel_trend`、`v_device_channel_conversion` | 各渠道整體表現、月度趨勢、裝置轉換分布 |
| `03_ctr_conversion.sql` | `v_campaign_daily_ctr_cvr`、`v_ctr_bucket_analysis`、`v_campaign_ctr_cvr_scatter` | CTR vs CVR 日級別、分桶分析、散點圖資料 |
| `04_roi_analysis.sql` | `v_campaign_roi`、`v_monthly_roi_trend`、`v_campaign_type_roi` | Campaign ROI 排名、月度 ROI 趨勢、Campaign Type 比較 |
| `05_dim_channel.sql` | `dim_channel_mapping`、`dim_channel`、`dim_campaign_type` | 渠道 & Campaign Type 維度表（含排序） |

---

## Power BI 儀表板（3 頁）

| 頁面 | 主題 | 核心圖表 |
|------|------|---------|
| Page 1 | Channel Overview | 渠道訂單排名、收益 vs 支出、ROAS 橫條圖、月度趨勢線、裝置 Donut |
| Page 2 | CTR vs Conversion | CTR×CVR 散點圖、Campaign 詳細表格、每日 CTR & CVR 折線柱狀圖 |
| Page 3 | ROI Analysis | Campaign ROI 排名、ROAS vs Spend 散點圖、Campaign Type 矩陣、月度 ROI 趨勢、CTR Bucket 圖 |

Dashboard PDF 匯出：[`powerbi/dashboard.pdf`](./powerbi/dashboard.pdf)

---

## 主要發現

### 渠道效益

| 渠道 | 訂單數 | 總收益 (USD) | CVR | ROAS |
|------|--------|-------------|-----|------|
| Google Ads | 11,732 | $1,118,727 | 3.54% | 2.15x |
| Facebook Ads | 2,797 | $246,650 | 2.65% | 1.38x |
| Direct | 1,979 | $215,525 | 6.83% | N/A |
| Email | 1,215 | $125,891 | **7.43%** | **30.8x** |
| Organic | 565 | $47,781 | 1.93% | N/A |

### Campaign ROI 排名（付費渠道）

| 排名 | Campaign | ROAS | ROI% | CPA (USD) |
|------|---------|------|------|-----------|
| 🥇 1 | Email_Abandoned_Cart | 45.12x | 4,412% | $2.27 |
| 🥈 2 | Email_Newsletter_Monthly | 27.86x | 2,686% | $3.74 |
| 🥉 3 | Email_Promo_Flash_Sale | 26.95x | 2,595% | $3.85 |
| 4 | Google_Shopping_Q1 | 3.54x | 254% | $26.98 |
| 5 | Facebook_Retargeting | 2.63x | 163% | $33.77 |
| ... | ... | ... | ... | ... |
| 🚨 Last | Google_Display_Remarketing | 0.70x | **-30%** | $132.36 |

### CTR vs CVR 洞察

在 Email 渠道篩選下，CTR 3–4% 區間的 CVR 最高（5.22%），而 CTR ≥ 5% 的 CVR 反而最低（3.47%）。**高 CTR ≠ 高 CVR**，廣告吸引力與購買意圖需分開評估。

---

## 快速開始

### 1. 安裝依賴

```bash
pip install pandas numpy faker google-cloud-bigquery pyarrow
```

### 2. 生成模擬資料

```bash
python scripts/01_generate_data.py
# 輸出：data/campaigns.csv, ad_impressions.csv, sessions.csv, conversions.csv
```

### 3. 上傳資料至 BigQuery

```bash
python scripts/02_upload_to_bigquery.py
# 目標：{project}.traffic_ad_roi.*
```

### 4. 執行 ETL & 分析 SQL

依序在 BigQuery 執行：

```
sql/01_data_cleaning.sql      → traffic_ad_roi_clean.* (cleaned tables)
sql/02_traffic_analysis.sql   → Views: v_channel_performance, v_monthly_channel_trend, v_device_channel_conversion
sql/03_ctr_conversion.sql     → Views: v_campaign_daily_ctr_cvr, v_ctr_bucket_analysis, v_campaign_ctr_cvr_scatter
sql/04_roi_analysis.sql       → Views: v_campaign_roi, v_monthly_roi_trend, v_campaign_type_roi
sql/05_dim_channel.sql        → Tables: dim_channel_mapping, dim_campaign_type_mapping; Views: dim_channel, dim_campaign_type
```

### 5. Power BI 連接

參考 [`powerbi/dashboard_design.md`](./powerbi/dashboard_design.md) 連接 BigQuery Views 並建立儀表板。

---

## 專案結構

```
03_Traffic_Sources_Ad_ROI_Analysis/
├── README.md
├── data/
│   ├── bigquery_cache_limit50/        # BigQuery Views 快取（前 50 筆，供離線參考）
│   └── .gitkeep                       # 原始 CSV（gitignore，不上傳大檔）
├── scripts/
│   ├── 01_generate_data.py            # 模擬資料生成（seed=42，可重現）
│   └── 02_upload_to_bigquery.py       # BigQuery 上傳（traffic_ad_roi dataset）
├── sql/
│   ├── 01_data_cleaning.sql           # ETL 清洗 & 驗證
│   ├── 02_traffic_analysis.sql        # 流量來源分析
│   ├── 03_ctr_conversion.sql          # CTR vs 轉換率分析
│   ├── 04_roi_analysis.sql            # ROI & ROAS 分析
│   ├── 05_dim_channel.sql             # 維度表（channel & campaign type）
│   └── screenshots/                   # SQL 執行結果截圖
├── powerbi/
│   ├── dashboard.pdf                  # Dashboard PDF 匯出
│   ├── dashboard_design.md            # Power BI 設計文件（視覺化規格 & DAX）
│   ├── background.png                 # Dashboard 背景圖
│   └── screenshots/                   # Dashboard 截圖
├── docs/
│   └── data_dictionary.md             # 資料字典（欄位說明、指標定義、Simulation Parameters）
├── error_reports/                     # ETL 錯誤報告
└── log.ipynb                          # 開發日誌 Notebook
```

---

## 資料模擬參數

| 渠道 | 基準 CTR | 基準 CVR | 平均客單價 |
|------|---------|---------|----------|
| Google Ads | 4.5% | 3.5% | $95 |
| Facebook Ads | 2.2% | 2.5% | $88 |
| Email | 2.8% | 5.5% | $102 |
| Organic | N/A | 3.0% | $85 |
| Direct | N/A | 4.5% | $110 |

> 資料以 `random.seed(42)` 固定，結果可完全重現。詳細欄位說明見 [`docs/data_dictionary.md`](./docs/data_dictionary.md)。

---

## 作者

Ross Tang | [GitHub](https://github.com/ross-bi)

## License

This project is licensed under the [MIT License](./LICENSE).
