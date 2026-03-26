-- ============================================================
-- 建 dim_channel_mapping 之前的預備檢查
-- ============================================================

-- 1. 查看 campaigns 現有所有唯一 channel（確認有哪些值需要加入 mapping）
SELECT DISTINCT channel, COUNT(*) AS campaign_count
FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
WHERE channel IS NOT NULL
GROUP BY channel
ORDER BY channel;


-- 2. 找出各表有但 campaigns 沒有的 channel（孤兒值）
SELECT 'conversions' AS source, channel
FROM `ross-bi-project-03.traffic_ad_roi_clean.conversions`
WHERE channel NOT IN (SELECT DISTINCT channel FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`)
UNION DISTINCT
SELECT 'sessions', channel
FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
WHERE channel NOT IN (SELECT DISTINCT channel FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`);

-- ============================================================
-- 建 dim_channel_mapping 
-- ============================================================


-- Step 1：建 mapping 表（只維護 sort_order）
CREATE OR REPLACE TABLE `ross-bi-project-03.traffic_ad_roi_clean.dim_channel_mapping` AS
SELECT * FROM UNNEST([
  STRUCT('Google Ads'   AS channel, 1 AS sort_order),
  STRUCT('Facebook Ads' AS channel, 2 AS sort_order),
  STRUCT('Email'        AS channel, 3 AS sort_order),
  STRUCT('Organic'      AS channel, 4 AS sort_order),
  STRUCT('Direct'       AS channel, 5 AS sort_order)
]);


-- Step 2：動態 view，新渠道自動包含，sort_order 預設 99
CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_ad_roi_clean.dim_channel` AS

SELECT
  c.channel,
  COALESCE(m.sort_order, 99) AS sort_order
FROM (
  SELECT DISTINCT channel
  FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
  WHERE channel IS NOT NULL
) c
LEFT JOIN `ross-bi-project-03.traffic_ad_roi_clean.dim_channel_mapping` m
  USING (channel)
ORDER BY sort_order;

-- ============================================================
-- 預備檢查：確認現有 campaign_type 唯一值
-- ============================================================

-- 1. 查看所有唯一 campaign_type 及數量
SELECT DISTINCT campaign_type, COUNT(*) AS campaign_count
FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
WHERE campaign_type IS NOT NULL
GROUP BY campaign_type
ORDER BY campaign_type;


-- ============================================================
-- 建 dim_campaign_type_mapping（只維護 sort_order）
-- ============================================================

CREATE OR REPLACE TABLE `ross-bi-project-03.traffic_ad_roi_clean.dim_campaign_type_mapping` AS
SELECT * FROM UNNEST([

  STRUCT('Search'      AS campaign_type, 1 AS sort_order),
  STRUCT('Shopping'    AS campaign_type, 2 AS sort_order),
  STRUCT('Display'     AS campaign_type, 3 AS sort_order),
  STRUCT('Awareness'   AS campaign_type, 4 AS sort_order),
  STRUCT('Conversion'  AS campaign_type, 5 AS sort_order),
  STRUCT('Retargeting' AS campaign_type, 6 AS sort_order),
  STRUCT('Promotion'   AS campaign_type, 7 AS sort_order),
  STRUCT('Newsletter'  AS campaign_type, 8 AS sort_order),
  STRUCT('Automation'  AS campaign_type, 9 AS sort_order),
  STRUCT('SEO'         AS campaign_type, 10 AS sort_order),
  STRUCT('Direct'      AS campaign_type, 11 AS sort_order)
]);


-- ============================================================
-- 建 dim_campaign_type（動態 View，新 type 自動包含，sort_order 預設 99）
-- ============================================================

CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_ad_roi_clean.dim_campaign_type` AS

SELECT
  c.campaign_type,
  COALESCE(m.sort_order, 99) AS sort_order
FROM (
  SELECT DISTINCT campaign_type
  FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
  WHERE campaign_type IS NOT NULL
) c
LEFT JOIN `ross-bi-project-03.traffic_ad_roi_clean.dim_campaign_type_mapping` m
  USING (campaign_type)
ORDER BY sort_order;
