-- ============================================================
-- 01_create_tables.sql
-- BigQuery DDL for Traffic Sources & Ad ROI Analysis
-- Dataset: traffic_ad_roi
-- ============================================================

-- ① campaigns — 廣告活動主檔
CREATE OR REPLACE TABLE `traffic_ad_roi.campaigns` (
    campaign_id   STRING    NOT NULL,
    campaign_name STRING,
    channel       STRING,       -- Google Ads / Facebook Ads / Email / Organic / Direct
    campaign_type STRING,       -- Search / Shopping / Display / Awareness / Conversion / ...
    daily_budget  FLOAT64,      -- USD
    start_date    DATE,
    end_date      DATE
)
OPTIONS (description = 'Ad campaign master table');


-- ② ad_impressions — 每日廣告曝光 & 點擊（付費渠道）
CREATE OR REPLACE TABLE `traffic_ad_roi.ad_impressions` (
    impression_id  STRING  NOT NULL,
    campaign_id    STRING,
    date           DATE,
    impressions    INT64,
    clicks         INT64,
    ctr            FLOAT64,   -- Click-Through Rate
    spend_usd      FLOAT64    -- Actual daily spend
)
PARTITION BY date
OPTIONS (description = 'Daily ad impression and click data per campaign');


-- ③ sessions — 網站 session 記錄
CREATE OR REPLACE TABLE `traffic_ad_roi.sessions` (
    session_id           STRING  NOT NULL,
    campaign_id          STRING,
    channel              STRING,
    session_date         DATE,
    session_ts           DATETIME,
    device               STRING,   -- desktop / mobile / tablet
    country              STRING,
    pages_viewed         INT64,
    session_duration_sec INT64,
    is_bounce            INT64     -- 1 = bounced, 0 = engaged
)
PARTITION BY session_date
OPTIONS (description = 'Website session records with traffic source attribution');


-- ④ conversions — 訂單轉換事件
CREATE OR REPLACE TABLE `traffic_ad_roi.conversions` (
    order_id        STRING  NOT NULL,
    session_id      STRING,
    campaign_id     STRING,
    channel         STRING,
    order_date      DATE,
    order_ts        DATETIME,
    order_value_usd FLOAT64,
    device          STRING,
    country         STRING
)
PARTITION BY order_date
OPTIONS (description = 'Order conversion events linked to sessions and campaigns');
