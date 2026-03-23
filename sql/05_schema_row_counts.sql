-- 目的：確認每張表的行數，讓我了解資料規模
SELECT 'campaigns'      AS tbl, COUNT(*) AS row_count FROM `ross-bi-project-03.traffic_ad_roi_clean.campaigns`
UNION ALL
SELECT 'ad_impressions', COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.ad_impressions`
UNION ALL
SELECT 'sessions',       COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.sessions`
UNION ALL
SELECT 'conversions',    COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.conversions`
UNION ALL
SELECT 'v_campaign_roi', COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_campaign_roi`
UNION ALL
SELECT 'v_channel_performance', COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_channel_performance`
UNION ALL
SELECT 'v_monthly_roi_trend',   COUNT(*) FROM `ross-bi-project-03.traffic_ad_roi_clean.v_monthly_roi_trend`;
