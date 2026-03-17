-- ============================================================
-- 03_roi_analysis.sql
-- 建立 ROI 分析用 View（不在 SQL 層計算 roi_pct / roas）
-- 前置條件：
-- 1. 02_data_cleaning.sql 已建立 cleaned_traffic view
-- 2. ad_campaigns 表已上傳到 BigQuery
-- ============================================================

CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_roi.roi_analysis_view` AS

WITH ga4_traffic AS (
  SELECT
    LOWER(TRIM(channel)) AS channel,
    LOWER(TRIM(campaign_name)) AS campaign_name_key,
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
    LOWER(TRIM(channel)) AS channel,
    LOWER(TRIM(campaign_name)) AS campaign_name_key,
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
  a.ad_spend,
  a.impressions,
  a.clicks,
  a.ctr_pct
FROM ga4_traffic g
LEFT JOIN ad_data a
  ON g.channel = a.channel
 AND g.campaign_name_key = a.campaign_name_key
ORDER BY
  g.is_paid_channel DESC,
  g.revenue DESC,
  g.campaign_name;
