-- ============================================================
-- 01_data_cleaning.sql
-- Data Cleaning & Validation for Traffic Sources & Ad ROI
-- Dataset  : traffic_ad_roi
-- Dialect  : Google BigQuery Standard SQL
-- Author   : ross-bi
-- Updated  : 2026-03-19
--
-- Execution order:
--   Step 1  — Validate & deduplicate source tables
--   Step 2  — Standardise & enrich each table
--   Step 3  — Write cleaned tables to traffic_ad_roi_clean.*
-- ============================================================


-- ============================================================
-- STEP 1 — VALIDATION CHECKS  (run first; review output before Step 2)
-- ============================================================

-- 1A  NULL / blank primary-key check
SELECT 'campaigns'      AS source_table, COUNT(*) AS null_pk_rows FROM `traffic_ad_roi.campaigns`     WHERE campaign_id   IS NULL OR TRIM(campaign_id)   = ''
UNION ALL
SELECT 'ad_impressions', COUNT(*) FROM `traffic_ad_roi.ad_impressions` WHERE impression_id IS NULL OR TRIM(impression_id) = ''
UNION ALL
SELECT 'sessions',       COUNT(*) FROM `traffic_ad_roi.sessions`       WHERE session_id    IS NULL OR TRIM(session_id)    = ''
UNION ALL
SELECT 'conversions',    COUNT(*) FROM `traffic_ad_roi.conversions`     WHERE order_id      IS NULL OR TRIM(order_id)      = '';


-- 1B  Duplicate primary-key check
SELECT 'campaigns'      AS source_table, campaign_id   AS pk, COUNT(*) AS cnt FROM `traffic_ad_roi.campaigns`     GROUP BY campaign_id   HAVING cnt > 1
UNION ALL
SELECT 'ad_impressions', impression_id, COUNT(*) FROM `traffic_ad_roi.ad_impressions` GROUP BY impression_id HAVING COUNT(*) > 1
UNION ALL
SELECT 'sessions',       session_id,    COUNT(*) FROM `traffic_ad_roi.sessions`       GROUP BY session_id    HAVING COUNT(*) > 1
UNION ALL
SELECT 'conversions',    order_id,      COUNT(*) FROM `traffic_ad_roi.conversions`     GROUP BY order_id      HAVING COUNT(*) > 1;


-- 1C  Referential integrity: impressions / sessions / conversions → campaigns
SELECT 'ad_impressions orphan' AS check_name, COUNT(*) AS orphan_rows
FROM   `traffic_ad_roi.ad_impressions` i
WHERE  i.campaign_id IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM `traffic_ad_roi.campaigns` c WHERE c.campaign_id = i.campaign_id)
UNION ALL
SELECT 'sessions orphan', COUNT(*)
FROM   `traffic_ad_roi.sessions` s
WHERE  s.campaign_id IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM `traffic_ad_roi.campaigns` c WHERE c.campaign_id = s.campaign_id)
UNION ALL
SELECT 'conversions orphan', COUNT(*)
FROM   `traffic_ad_roi.conversions` v
WHERE  v.campaign_id IS NOT NULL
  AND  NOT EXISTS (SELECT 1 FROM `traffic_ad_roi.campaigns` c WHERE c.campaign_id = v.campaign_id);


-- 1D  Out-of-range numeric values
SELECT
  'ad_impressions'         AS source_table,
  COUNTIF(impressions < 0) AS neg_impressions,
  COUNTIF(clicks < 0)      AS neg_clicks,
  COUNTIF(clicks > impressions AND impressions IS NOT NULL) AS clicks_gt_impressions,
  COUNTIF(ctr < 0 OR ctr > 1)   AS invalid_ctr,
  COUNTIF(spend_usd < 0)         AS neg_spend
FROM `traffic_ad_roi.ad_impressions`;

SELECT
  'sessions'                        AS source_table,
  COUNTIF(pages_viewed < 1)         AS invalid_pages,
  COUNTIF(session_duration_sec < 0) AS neg_duration,
  COUNTIF(is_bounce NOT IN (0, 1))  AS invalid_bounce_flag
FROM `traffic_ad_roi.sessions`;

SELECT
  'conversions'                 AS source_table,
  COUNTIF(order_value_usd <= 0) AS non_positive_order_value
FROM `traffic_ad_roi.conversions`;


-- 1E  Date logic check for campaigns
SELECT campaign_id, start_date, end_date
FROM   `traffic_ad_roi.campaigns`
WHERE  end_date < start_date;


-- ============================================================
-- STEP 2 — CLEAN & STANDARDISE  →  write to *_clean dataset
-- ============================================================

-- Target dataset must exist first:
-- CREATE SCHEMA IF NOT EXISTS `traffic_ad_roi_clean`;


-- ─────────────────────────────────────────────────────────
-- 2A  campaigns_clean
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE `traffic_ad_roi_clean.campaigns` AS

WITH deduped AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY campaign_id ORDER BY start_date DESC) AS rn
  FROM `traffic_ad_roi.campaigns`
  WHERE campaign_id IS NOT NULL
    AND TRIM(campaign_id) <> ''
)

SELECT
  TRIM(campaign_id)                                                         AS campaign_id,

  CASE WHEN TRIM(campaign_name) = '' OR campaign_name IS NULL
       THEN 'Unknown'
       ELSE INITCAP(TRIM(campaign_name)) END                                AS campaign_name,

  CASE UPPER(TRIM(channel))
    WHEN 'GOOGLE ADS'    THEN 'Google Ads'
    WHEN 'GOOGLE'        THEN 'Google Ads'
    WHEN 'FACEBOOK ADS'  THEN 'Facebook Ads'
    WHEN 'FACEBOOK'      THEN 'Facebook Ads'
    WHEN 'EMAIL'         THEN 'Email'
    WHEN 'ORGANIC'       THEN 'Organic'
    WHEN 'DIRECT'        THEN 'Direct'
    ELSE COALESCE(NULLIF(TRIM(channel), ''), 'Unknown')
  END                                                                       AS channel,

  CASE UPPER(TRIM(campaign_type))
    WHEN 'SEARCH'      THEN 'Search'
    WHEN 'SHOPPING'    THEN 'Shopping'
    WHEN 'DISPLAY'     THEN 'Display'
    WHEN 'AWARENESS'   THEN 'Awareness'
    WHEN 'CONVERSION'  THEN 'Conversion'
    ELSE COALESCE(NULLIF(TRIM(campaign_type), ''), 'Unknown')
  END                                                                       AS campaign_type,

  GREATEST(COALESCE(daily_budget, 0), 0)                                   AS daily_budget_usd,
  start_date,
  CASE WHEN end_date < start_date THEN NULL ELSE end_date END              AS end_date,

  CASE
    WHEN end_date IS NULL OR end_date >= CURRENT_DATE() THEN TRUE
    ELSE FALSE
  END                                                                       AS is_active,

  CURRENT_TIMESTAMP()                                                       AS cleaned_at

FROM deduped
WHERE rn = 1;


-- ─────────────────────────────────────────────────────────
-- 2B  ad_impressions_clean
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE `traffic_ad_roi_clean.ad_impressions`
PARTITION BY date
AS

WITH deduped AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY impression_id ORDER BY date DESC) AS rn
  FROM `traffic_ad_roi.ad_impressions`
  WHERE impression_id IS NOT NULL
    AND TRIM(impression_id) <> ''
)

SELECT
  TRIM(impression_id)                                                       AS impression_id,
  TRIM(campaign_id)                                                         AS campaign_id,
  date,
  GREATEST(COALESCE(impressions, 0), 0)                                     AS impressions,
  GREATEST(COALESCE(clicks, 0), 0)                                          AS clicks,

  -- Recalculate CTR from raw counts (more reliable than stored value)
  CASE
    WHEN GREATEST(COALESCE(impressions, 0), 0) = 0 THEN 0
    ELSE ROUND(SAFE_DIVIDE(
           GREATEST(COALESCE(clicks, 0), 0),
           GREATEST(COALESCE(impressions, 0), 0)
         ), 6)
  END                                                                       AS ctr_calculated,

  ROUND(GREATEST(LEAST(COALESCE(ctr, 0), 1), 0), 6)                       AS ctr_original,
  GREATEST(COALESCE(spend_usd, 0), 0)                                       AS spend_usd,

  ROUND(SAFE_DIVIDE(
    GREATEST(COALESCE(spend_usd, 0), 0),
    GREATEST(COALESCE(clicks, 0), 0)
  ), 4)                                                                     AS cost_per_click_usd,

  CURRENT_TIMESTAMP()                                                       AS cleaned_at

FROM deduped
WHERE rn = 1;


-- ─────────────────────────────────────────────────────────
-- 2C  sessions_clean
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE `traffic_ad_roi_clean.sessions`
PARTITION BY session_date
AS

WITH deduped AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY session_id ORDER BY session_ts DESC) AS rn
  FROM `traffic_ad_roi.sessions`
  WHERE session_id IS NOT NULL
    AND TRIM(session_id) <> ''
)

SELECT
  TRIM(session_id)                                                          AS session_id,
  TRIM(campaign_id)                                                         AS campaign_id,

  CASE UPPER(TRIM(channel))
    WHEN 'GOOGLE ADS'    THEN 'Google Ads'
    WHEN 'GOOGLE'        THEN 'Google Ads'
    WHEN 'FACEBOOK ADS'  THEN 'Facebook Ads'
    WHEN 'FACEBOOK'      THEN 'Facebook Ads'
    WHEN 'EMAIL'         THEN 'Email'
    WHEN 'ORGANIC'       THEN 'Organic'
    WHEN 'DIRECT'        THEN 'Direct'
    ELSE COALESCE(NULLIF(TRIM(channel), ''), 'Unknown')
  END                                                                       AS channel,

  session_date,
  session_ts,

  CASE LOWER(TRIM(device))
    WHEN 'desktop' THEN 'Desktop'
    WHEN 'mobile'  THEN 'Mobile'
    WHEN 'tablet'  THEN 'Tablet'
    ELSE 'Unknown'
  END                                                                       AS device,

  UPPER(TRIM(COALESCE(country, 'Unknown')))                                AS country,
  GREATEST(COALESCE(pages_viewed, 1), 1)                                   AS pages_viewed,
  GREATEST(COALESCE(session_duration_sec, 0), 0)                           AS session_duration_sec,
  CASE WHEN is_bounce IN (0, 1) THEN is_bounce ELSE NULL END               AS is_bounce,

  CASE
    WHEN COALESCE(session_duration_sec, 0) >= 180 AND COALESCE(pages_viewed, 1) >= 3 THEN 'High'
    WHEN COALESCE(session_duration_sec, 0) >= 60  AND COALESCE(pages_viewed, 1) >= 2 THEN 'Medium'
    ELSE 'Low'
  END                                                                       AS engagement_tier,

  CURRENT_TIMESTAMP()                                                       AS cleaned_at

FROM deduped
WHERE rn = 1;


-- ─────────────────────────────────────────────────────────
-- 2D  conversions_clean
-- ─────────────────────────────────────────────────────────
CREATE OR REPLACE TABLE `traffic_ad_roi_clean.conversions`
PARTITION BY order_date
AS

WITH deduped AS (
  SELECT *,
         ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY order_ts DESC) AS rn
  FROM `traffic_ad_roi.conversions`
  WHERE order_id IS NOT NULL
    AND TRIM(order_id) <> ''
)

SELECT
  TRIM(order_id)                                                            AS order_id,
  TRIM(session_id)                                                          AS session_id,
  TRIM(campaign_id)                                                         AS campaign_id,

  CASE UPPER(TRIM(channel))
    WHEN 'GOOGLE ADS'    THEN 'Google Ads'
    WHEN 'GOOGLE'        THEN 'Google Ads'
    WHEN 'FACEBOOK ADS'  THEN 'Facebook Ads'
    WHEN 'FACEBOOK'      THEN 'Facebook Ads'
    WHEN 'EMAIL'         THEN 'Email'
    WHEN 'ORGANIC'       THEN 'Organic'
    WHEN 'DIRECT'        THEN 'Direct'
    ELSE COALESCE(NULLIF(TRIM(channel), ''), 'Unknown')
  END                                                                       AS channel,

  order_date,
  order_ts,
  CASE WHEN order_value_usd > 0 THEN order_value_usd ELSE NULL END         AS order_value_usd,

  CASE
    WHEN order_value_usd IS NULL OR order_value_usd <= 0 THEN 'Invalid'
    WHEN order_value_usd >= 500  THEN 'High Value'
    WHEN order_value_usd >= 100  THEN 'Mid Value'
    ELSE 'Low Value'
  END                                                                       AS order_value_tier,

  CASE LOWER(TRIM(device))
    WHEN 'desktop' THEN 'Desktop'
    WHEN 'mobile'  THEN 'Mobile'
    WHEN 'tablet'  THEN 'Tablet'
    ELSE 'Unknown'
  END                                                                       AS device,

  UPPER(TRIM(COALESCE(country, 'Unknown')))                                AS country,
  CURRENT_TIMESTAMP()                                                       AS cleaned_at

FROM deduped
WHERE rn = 1
  AND order_value_usd > 0;


-- ============================================================
-- STEP 3 — CLEANING SUMMARY REPORT
-- ============================================================

SELECT
  'campaigns'                                                               AS table_name,
  (SELECT COUNT(*) FROM `traffic_ad_roi.campaigns`)                        AS raw_rows,
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.campaigns`)                  AS clean_rows,
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.campaigns` WHERE channel = 'Unknown') AS unknown_channel
UNION ALL
SELECT
  'ad_impressions',
  (SELECT COUNT(*) FROM `traffic_ad_roi.ad_impressions`),
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.ad_impressions`),
  NULL
UNION ALL
SELECT
  'sessions',
  (SELECT COUNT(*) FROM `traffic_ad_roi.sessions`),
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.sessions`),
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.sessions` WHERE channel = 'Unknown')
UNION ALL
SELECT
  'conversions',
  (SELECT COUNT(*) FROM `traffic_ad_roi.conversions`),
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.conversions`),
  (SELECT COUNT(*) FROM `traffic_ad_roi_clean.conversions` WHERE channel = 'Unknown');