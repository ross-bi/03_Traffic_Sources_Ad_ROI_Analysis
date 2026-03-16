-- ============================================================
-- 01_data_cleaning.sql
-- 清洗 GA4 流量資料，建立 cleaned_traffic view
-- 執行順序：此檔案必須最先執行
-- ============================================================

CREATE OR REPLACE VIEW `your_project.traffic_roi.cleaned_traffic` AS

WITH raw_traffic AS (
  SELECT
    trafficSource.medium      AS channel,
    trafficSource.campaign    AS campaign_name,
    trafficSource.source      AS source,
    COUNT(DISTINCT fullVisitorId)            AS sessions,
    SUM(totals.transactions)                 AS conversions,
    SUM(totals.transactionRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  GROUP BY 1, 2, 3
)

SELECT
  -- 1. 標準化 channel 名稱（統一小寫去空格）
  LOWER(TRIM(channel))                                              AS channel,

  -- 2. 處理 NULL / 空白 campaign，填入 '(not set)'
  COALESCE(NULLIF(TRIM(campaign_name), ''), '(not set)')            AS campaign_name,

  -- 3. 標準化 source
  LOWER(TRIM(source))                                               AS source,

  sessions,

  -- 4. 處理 NULL conversions（填 0）
  COALESCE(conversions, 0)                                          AS conversions,

  -- 5. 處理 NULL revenue（填 0）
  COALESCE(revenue, 0)                                              AS revenue,

  -- 6. 計算轉換率，避免除以零
  ROUND(
    COALESCE(conversions, 0) / NULLIF(sessions, 0) * 100, 2
  )                                                                 AS conversion_rate_pct,

  -- 7. 保留所有 channel 資料完整性，加標記欄位供後續篩選
  --    is_paid_channel = TRUE  → 有廣告花費，可計算 ROI
  --    is_paid_channel = FALSE → direct / organic，不計算 ROI
  CASE
    WHEN LOWER(TRIM(channel)) IN ('cpc', 'cpm', 'cpv', 'affiliate')
    THEN TRUE
    ELSE FALSE
  END                                                               AS is_paid_channel,

  -- 8. channel 分類標籤（供 Power BI Slicer 使用）
  CASE
    WHEN LOWER(TRIM(channel)) IN ('cpc', 'cpm', 'cpv', 'affiliate') THEN 'Paid'
    WHEN LOWER(TRIM(channel)) = 'organic'                           THEN 'Organic'
    WHEN LOWER(TRIM(channel)) = 'email'                             THEN 'Email'
    WHEN LOWER(TRIM(channel)) = 'referral'                          THEN 'Referral'
    WHEN LOWER(TRIM(channel)) = 'direct' OR channel IS NULL         THEN 'Direct'
    ELSE 'Other'
  END                                                               AS channel_category

FROM raw_traffic

-- 9. 只排除 sessions = 0 的完全無效資料，保留所有 channel
WHERE sessions > 0
  AND channel IS NOT NULL;
