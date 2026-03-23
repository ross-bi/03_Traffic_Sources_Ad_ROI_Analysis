-- View 1：每日 × 渠道 × 裝置（替代原始 sessions）
CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_daily_summary` AS

SELECT
  session_date,
  channel,
  device,
  country,
  engagement_tier,
  COUNT(*)                              AS total_sessions,
  COUNTIF(is_bounce = 1)               AS bounced_sessions,
  SUM(pages_viewed)                    AS total_pages_viewed,
  SUM(session_duration_sec)            AS total_duration_sec,
  COUNTIF(engagement_tier = 'High')    AS high_engagement_sessions,
  COUNTIF(engagement_tier = 'Medium')  AS medium_engagement_sessions,
  COUNTIF(engagement_tier = 'Low')     AS low_engagement_sessions
FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
GROUP BY
  session_date, channel, device, country, engagement_tier;


-- View 2：每月 × 渠道摘要（用於 Page 3 趨勢）
CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_monthly_summary` AS

SELECT
  FORMAT_DATE('%Y-%m', session_date)   AS year_month,
  channel,
  device,
  COUNT(*)                             AS total_sessions,
  COUNTIF(is_bounce = 1)              AS bounced_sessions,
  ROUND(AVG(session_duration_sec), 1) AS avg_duration_sec,
  ROUND(AVG(pages_viewed), 2)         AS avg_pages_viewed,
  COUNTIF(engagement_tier = 'High')   AS high_engagement_sessions
FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
GROUP BY year_month, channel, device;

-- View 3：國家 × 渠道摘要（用於地圖/國家分析）
CREATE OR REPLACE VIEW `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_country_summary` AS

SELECT
  country,
  channel,
  device,
  COUNT(*)                             AS total_sessions,
  COUNTIF(is_bounce = 1)              AS bounced_sessions,
  ROUND(AVG(session_duration_sec), 1) AS avg_duration_sec
FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
GROUP BY country, channel, device;

-- 確認 row count
SELECT 'v_sessions_daily_summary',   COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_daily_summary`
UNION ALL
SELECT 'v_sessions_monthly_summary', COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_monthly_summary`
UNION ALL
SELECT 'v_sessions_country_summary', COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_sessions_country_summary`;