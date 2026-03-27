# 数据字典
## Traffic Sources & Ad ROI Analysis

---

## 一、原始数据表（`traffic_ad_roi.*`）

### Table: `campaigns`

| 字段 | 类型 | 说明 | 范例 |
|------|------|------|------|
| campaign_id | STRING | 广告活动唯一标识符 | C001 |
| campaign_name | STRING | 广告活动名称 | Google_Brand_Search |
| channel | STRING | 流量渠道 | Google Ads / Facebook Ads / Email / Organic / Direct |
| campaign_type | STRING | 广告类型 | Search / Shopping / Display / Awareness / Conversion / Retargeting / Newsletter / Promotion / Automation / SEO / Direct |
| daily_budget | FLOAT64 | 每日预算（USD） | 500.00 |
| start_date | DATE | 活动开始日期 | 2024-01-01 |
| end_date | DATE | 活动结束日期 | 2024-12-31 |

---

### Table: `ad_impressions`

| 字段 | 类型 | 说明 | 范例 |
|------|------|------|------|
| impression_id | STRING | 每日曝光记录唯一标识符 | IMP-C001-20240101 |
| campaign_id | STRING | 关联广告活动 FK | C001 |
| date | DATE | 记录日期（Partition Key） | 2024-01-15 |
| impressions | INT64 | 广告曝光次数 | 6000 |
| clicks | INT64 | 广告点击次数 | 270 |
| ctr | FLOAT64 | 点击率 = clicks / impressions（原始值） | 0.045 |
| spend_usd | FLOAT64 | 当日广告支出（USD） | 486.00 |

> **注意**：Organic 与 Direct 渠道的 `clicks` / `ctr` / `spend_usd` 均为 0，因为这些渠道无广告支出。

---

### Table: `sessions`

| 字段 | 类型 | 说明 | 范例 |
|------|------|------|------|
| session_id | STRING | Session 唯一标识符 | S00000001 |
| campaign_id | STRING | 来源广告活动 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| session_date | DATE | Session 日期（Partition Key） | 2024-01-15 |
| session_ts | DATETIME | Session 开始时间戳 | 2024-01-15 14:32:11 |
| device | STRING | 装置类型 | desktop / mobile / tablet |
| country | STRING | 用户国家代码（ISO 2码） | HK / SG / TW / US |
| pages_viewed | INT64 | 浏览页数 | 4 |
| session_duration_sec | INT64 | Session 时长（秒） | 215 |
| is_bounce | INT64 | 是否为跳出 Session（1=是，0=否） | 0 |

---

### Table: `conversions`

| 字段 | 类型 | 说明 | 范例 |
|------|------|------|------|
| order_id | STRING | 订单唯一标识符 | ORD-0000001 |
| session_id | STRING | 关联 Session FK | S00000001 |
| campaign_id | STRING | 来源广告活动 FK | C001 |
| channel | STRING | 流量渠道 | Google Ads |
| order_date | DATE | 订单日期（Partition Key） | 2024-01-15 |
| order_ts | DATETIME | 订单时间戳 | 2024-01-15 14:45:22 |
| order_value_usd | FLOAT64 | 订单金额（USD） | 97.50 |
| device | STRING | 下单装置 | mobile |
| country | STRING | 用户国家代码（ISO 2码） | HK |

---

## 二、清洗后数据表（`traffic_ad_roi_clean.*`）

由 `01_data_cleaning.sql` 生成，以下列出各表相对于原始表**新增或修改**的字段。

### Table: `campaigns`（cleaned）

| 字段 | 类型 | 说明 | 异动说明 |
|------|------|------|---------|
| campaign_name | STRING | 广告活动名称（标准化） | NULL / 空白补为 `'Unknown'`；套用 `INITCAP` 格式 |
| channel | STRING | 流量渠道（标准化） | 统一大小写，如 `'GOOGLE'` → `'Google Ads'` |
| campaign_type | STRING | 广告类型（标准化） | 统一大小写，如 `'SEARCH'` → `'Search'` |
| daily_budget_usd | FLOAT64 | 每日预算（USD，修正后） | 原字段重命名；NULL 补 0，负值修正为 0 |
| end_date | DATE | 活动结束日期 | `end_date < start_date` 时设为 NULL |
| **is_active** | BOOLEAN | 是否仍在投放中 | **新增**：`end_date IS NULL OR end_date >= CURRENT_DATE()` |
| **cleaned_at** | TIMESTAMP | ETL 清洗时间戳 | **新增** |

---

### Table: `ad_impressions`（cleaned）

| 字段 | 类型 | 说明 | 异动说明 |
|------|------|------|---------|
| impressions | INT64 | 广告曝光次数（修正后） | NULL 补 0，负值修正为 0 |
| clicks | INT64 | 广告点击次数（修正后） | NULL 补 0，负值修正为 0 |
| **ctr_calculated** | FLOAT64 | 从原始数值重新计算的 CTR | **新增**：`SAFE_DIVIDE(clicks, impressions)`，impressions=0 时为 0 |
| ctr_original | FLOAT64 | 原始储存的 CTR 值 | 原 `ctr` 字段重命名；限缩至 [0,1] 范围 |
| spend_usd | FLOAT64 | 广告支出（修正后） | NULL 补 0，负值修正为 0 |
| **cost_per_click_usd** | FLOAT64 | 每次点击成本（CPC） | **新增**：`SAFE_DIVIDE(spend_usd, clicks)` |
| **cleaned_at** | TIMESTAMP | ETL 清洗时间戳 | **新增** |

---

### Table: `sessions`（cleaned）

| 字段 | 类型 | 说明 | 异动说明 |
|------|------|------|---------|
| channel | STRING | 流量渠道（标准化） | 统一大小写格式 |
| device | STRING | 装置类型（标准化） | 统一首字大写：`Desktop` / `Mobile` / `Tablet`；其他补 `'Unknown'` |
| country | STRING | 国家代码（标准化） | `UPPER(TRIM(...))` 统一大写；NULL 补 `'Unknown'` |
| pages_viewed | INT64 | 浏览页数（修正后） | 最小值限为 1 |
| session_duration_sec | INT64 | Session 时长（修正后） | 负值修正为 0 |
| is_bounce | INT64 | 跳出标记（验证后） | 非 0/1 值设为 NULL |
| **engagement_tier** | STRING | 互动深度分层 | **新增**：`High`（时长≥180s 且 页数≥3）/ `Medium`（时长≥60s 且 页数≥2）/ `Low`（其他） |
| **cleaned_at** | TIMESTAMP | ETL 清洗时间戳 | **新增** |

---

### Table: `conversions`（cleaned）

| 字段 | 类型 | 说明 | 异动说明 |
|------|------|------|---------|
| channel | STRING | 流量渠道（标准化） | 统一大小写格式 |
| order_value_usd | FLOAT64 | 订单金额（验证后） | ≤ 0 的值设为 NULL；整笔记录同时被过滤移除 |
| **order_value_tier** | STRING | 订单金额分层 | **新增**：`High Value`（≥$500）/ `Mid Value`（≥$100）/ `Low Value`（其他）/ `Invalid`（≤0）|
| device | STRING | 下单装置（标准化） | 统一首字大写；其他补 `'Unknown'` |
| country | STRING | 国家代码（标准化） | `UPPER(TRIM(...))` 统一大写；NULL 补 `'Unknown'` |
| **cleaned_at** | TIMESTAMP | ETL 清洗时间戳 | **新增** |

---

## 三、分析指标定义

| 指标 | 公式 | 说明 |
|------|------|------|
| CTR (Click-Through Rate) | `clicks ÷ impressions` | 广告点击率 |
| CVR (Conversion Rate) | `orders ÷ sessions` | Session 转换率（以 Session 为分母）|
| Click CVR | `orders ÷ clicks` | 点击到订单转换率（以 Clicks 为分母）|
| CPC (Cost Per Click) | `spend ÷ clicks` | 每次点击成本 |
| CPM (Cost Per Mille) | `spend ÷ impressions × 1,000` | 每千次曝光成本 |
| CPA (Cost Per Acquisition) | `spend ÷ orders` | 每次转换成本 |
| ROAS (Return on Ad Spend) | `revenue ÷ spend` | 广告支出回报率（倍数）|
| ROI% | `(revenue − spend) ÷ spend × 100` | 投资报酬率（百分比）|

---

## 四、分析 Views 说明

| View 名称 | 来源 SQL | 说明 |
|-----------|---------|------|
| `v_channel_performance` | `02_traffic_analysis.sql` | 各渠道整体表现：订单数、收益、CVR、总支出、ROAS |
| `v_monthly_channel_trend` | `02_traffic_analysis.sql` | 各渠道月度订单与收益趋势（2024 全年）|
| `v_device_channel_conversion` | `02_traffic_analysis.sql` | 装置 × 渠道交叉转换分布 |
| `v_campaign_daily_ctr_cvr` | `03_ctr_conversion.sql` | 各 Campaign 日级别 CTR 与 CVR 趋势 |
| `v_ctr_bucket_analysis` | `03_ctr_conversion.sql` | CTR 分桶（<1%、1–2%、…、≥5%）对应的 CVR 分析 |
| `v_campaign_ctr_cvr_scatter` | `03_ctr_conversion.sql` | Campaign 层级散点图资料（CTR vs CVR，气泡大小=订单量）|
| `v_campaign_roi` | `04_roi_analysis.sql` | 各 Campaign 总支出、总收益、ROAS、ROI%、CPA |
| `v_monthly_roi_trend` | `04_roi_analysis.sql` | 月度 ROAS 与 ROI 趋势 |
| `v_campaign_type_roi` | `04_roi_analysis.sql` | 依 Campaign Type 汇总的 ROI 比较 |
| `dim_channel` | `05_dim_channel.sql` | 渠道维度表（含展示排序）|
| `dim_campaign_type` | `05_dim_channel.sql` | Campaign Type 维度表（含展示排序）|

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

## 六、模拟参数（Simulation Parameters）

| 渠道 | 基准 CTR | 基准 CVR | 平均客单价 | 适用 Campaign Type |
|------|---------|---------|----------|-------------------|
| Google Ads | 4.5% | 3.5% | $95 | Search / Shopping / Display |
| Facebook Ads | 2.2% | 2.5% | $88 | Awareness / Conversion / Retargeting |
| Email | 2.8% | 5.5% | $102 | Newsletter / Promotion / Automation |
| Organic | N/A | 3.0% | $85 | SEO |
| Direct | N/A | 4.5% | $110 | Direct |

**Campaign Type 修正系数（相对基准 CVR）：**

| Campaign Type | CVR 乘数 | CPC 乘数 | 说明 |
|--------------|---------|---------|------|
| Search | 1.20x | 1.8x | 主动搜寻意图高，转换率高于平均 |
| Shopping | 1.10x | 0.9x | 带有产品图片，转换意图较强 |
| Display | 0.70x | 0.5x | 品牌曝光为主，转换率较低 |
| Awareness | 0.60x | 0.8x | 纯上漏斗，转换率最低 |
| Conversion | 1.30x | 1.5x | 直接以转换为目标，效率高 |
| Retargeting | 1.50x | 1.2x | 再营销受众转换意图强 |
| Newsletter | 1.00x | 0.1x | 订阅用户基准转换率，成本极低 |
| Promotion | 1.40x | 0.1x | 促销驱动，转换率高，成本低 |
| Automation | 1.60x | 0.05x | 弃购车触发，最高转换率，成本最低 |
| SEO | 1.00x | 0.0x | 无广告支出 |
| Direct | 1.00x | 0.0x | 无广告支出 |

> 所有数值以 `random.seed(42)` 固定，加入季节性乘数（Q4：×1.3；Q1 春季：×1.1；其他：×1.0）。

---

## 七、国家代码对照

| 代码 | 国家/地区 | 模拟权重 |
|------|----------|---------|
| HK | 香港 | 35% |
| SG | 新加坡 | 20% |
| TW | 台湾 | 15% |
| US | 美国 | 10% |
| GB | 英国 | 5% |
| AU | 澳洲 | 5% |
| JP | 日本 | 5% |
| MY | 马来西亚 | 5% |

