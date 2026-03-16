-- ============================================================
-- 03_roi_analysis.sql
-- 流量來源 + 廣告 ROI 分析
-- 前置條件：02_data_cleaning.sql 必須先執行
--              ad_campaigns 表必須已上傳到 BigQuery
-- ============================================================

WITH ga4_traffic AS (
  -- 讀取清洗後的 view，不再直接查詢 GA4 原始表
  SELECT
    channel,
    campaign_name,
    source,
    sessions,
    conversions,
    revenue,
    conversion_rate_pct,
    is_paid_channel,
    channel_category
  FROM `ross-bi-project-03.traffic_roi.cleaned_traffic`
),

ad_data AS (
  SELECT
    channel,
    campaign_name,
    ad_spend,
    impressions,
    clicks,
    ROUND(clicks / NULLIF(impressions, 0) * 100, 2) AS ctr_pct
  FROM `ross-bi-project-03.traffic_roi.ad_campaigns`
)

SELECT
  g.channel,
  g.channel_category,
  g.campaign_name,
  g.source,
  g.sessions,
  g.conversions,
  g.conversion_rate_pct,
  g.revenue,
  g.is_paid_channel,

  -- 廣告數據（僅 Paid channel 才會有對應値）
  a.ad_spend,
  a.impressions,
  a.clicks,
  a.ctr_pct,

  -- ROI 計算（僅 is_paid_channel = TRUE 有意義）
  ROUND((g.revenue - a.ad_spend) / NULLIF(a.ad_spend, 0) * 100, 2) AS roi_pct,

  -- ROAS ＝ Revenue / Ad Spend
  ROUND(g.revenue / NULLIF(a.ad_spend, 0), 2)                       AS roas

FROM ga4_traffic g
LEFT JOIN ad_data a
  ON g.channel = a.channel
ORDER BY
  g.is_paid_channel DESC,
  roi_pct DESC;
