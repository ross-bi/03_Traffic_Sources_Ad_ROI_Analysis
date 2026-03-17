# 03 Traffic Sources & Ad ROI Analysis

## 專案概述

本專案分析各流量來源（Google Ads、Facebook Ads、Email、Organic、Direct）的廣告效益與投資報酬率（ROI），透過 Python 生成模擬資料，載入 BigQuery 進行分析，並以 Power BI 呈現視覺化儀表板。

## 業務問題

1. **哪些流量來源帶來最多轉換？** — 比較 Google、Facebook、Email、Organic、Direct 各渠道的轉換量與轉換率
2. **廣告點擊率（CTR）與訂單轉換率的關聯性** — 高 CTR 是否真的帶來更多訂單？
3. **不同廣告活動的 ROI** — 每個 Campaign 的廣告支出回報率（ROAS）與淨 ROI

## 技術架構

| 層級 | 工具 |
|------|------|
| 資料生成 | Python (Faker, Pandas) |
| 資料倉儲 | Google BigQuery |
| 資料轉換 | SQL |
| 視覺化 | Power BI Desktop |

## 資料模型

```
campaigns          ← 廣告活動主檔
    ↓
ad_impressions     ← 廣告曝光 & 點擊事件
    ↓
sessions           ← 網站瀏覽 Session
    ↓
conversions        ← 訂單轉換事件
```

## 快速開始

### 1. 安裝依賴
```bash
pip install pandas faker google-cloud-bigquery pyarrow
```

### 2. 生成模擬資料
```bash
python scripts/01_generate_data.py
```

### 3. 建立 BigQuery 資料表
```sql
-- 執行 sql/01_create_tables.sql
```

### 4. 上傳資料至 BigQuery
```bash
python scripts/02_upload_to_bigquery.py
```

### 5. 執行分析 SQL
依序執行 `sql/` 資料夾中的 02、03、04 分析腳本

### 6. Power BI 連接
參考 `powerbi/dashboard_design.md` 建立儀表板

## 專案結構

```
03_Traffic_Sources_Ad_ROI_Analysis/
├── README.md
├── data/                          # 本地 CSV 資料（gitignore 大檔）
├── scripts/
│   ├── 01_generate_data.py        # 模擬資料生成
│   └── 02_upload_to_bigquery.py   # BigQuery 上傳
├── sql/
│   ├── 01_create_tables.sql       # DDL 建表
│   ├── 02_traffic_analysis.sql    # 流量來源分析
│   ├── 03_ctr_conversion.sql      # CTR vs 轉換率
│   └── 04_roi_analysis.sql        # ROI 分析
├── powerbi/
│   └── dashboard_design.md        # Power BI 設計文件
└── docs/
    └── data_dictionary.md         # 資料字典
```

## 主要發現（範例）

- Google Ads 帶來最高轉換量，但 Email 的轉換率最高
- CTR > 3% 的廣告活動平均訂單轉換率高出 2.1 倍
- ROI 最高的活動集中在再行銷（Remarketing）類型

## 作者

ross-bi | [GitHub](https://github.com/ross-bi)
