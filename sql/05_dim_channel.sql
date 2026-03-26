-- ============================================================
-- 建 dim_channel_mapping 之前的預備檢查
-- ============================================================

-- 1. 查看 campaigns 現有所有唯一 channel（確認有哪些值需要加入 mapping）
SELECT DISTINCT channel, COUNT(*) AS campaign_count
FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
WHERE channel IS NOT NULL
GROUP BY channel
ORDER BY channel;


-- 2. 跨表確認：所有表的 channel 值是否一致
SELECT 'campaigns'              AS source, channel FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
UNION DISTINCT
SELECT 'conversions',             channel FROM `ross-bi-project-03.traffic_ad_roi_clean.conversions`
UNION DISTINCT
SELECT 'sessions',                channel FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
UNION DISTINCT
SELECT 'v_channel_performance',   channel FROM `ross-bi-project-03.traffic_ad_roi_clean.v_channel_performance`
ORDER BY channel;


-- 3. 找出各表有但 campaigns 沒有的 channel（孤兒值）
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
