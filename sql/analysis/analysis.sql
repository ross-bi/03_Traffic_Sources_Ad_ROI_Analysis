-- A1.
-- Direct Mobile AOV $109.84 最高，但 v_device_channel_conversion View 只有訂單數和收益，
-- 沒有 CPA / CVR 分裝置的分析 SQL。Notion 展示時這一洞察缺乏 SQL 佐證。
-- 補充：裝置 × 渠道的 CVR 與 AOV
SELECT
    c.channel,
    s.device,
    COUNT(DISTINCT s.session_id)      AS sessions,
    COUNT(v.order_id)                 AS orders,
    ROUND(SAFE_DIVIDE(COUNT(v.order_id), COUNT(DISTINCT s.session_id)) * 100, 2) AS cvr_pct,
    ROUND(AVG(v.order_value_usd), 2)  AS avg_order_value
FROM `traffic_ad_roi_clean.sessions`    s
LEFT JOIN `traffic_ad_roi_clean.conversions` v ON v.session_id = s.session_id
JOIN `traffic_ad_roi_clean.campaigns`   c ON c.campaign_id = s.campaign_id
GROUP BY 1, 2
ORDER BY 1, cvr_pct DESC;

-- A2.
-- 月度趨勢文字敘述，但 Notion 裡需要一個可複製的數字佐證：
-- Email 全年僅花 $4,087 vs Google Ads $521,497，以月份拆分的 ROAS 對比 SQL 尚未出現。
-- 補充：月度 Email 與 Google Ads ROI 對比
SELECT
    FORMAT_DATE('%Y-%m', i.date)         AS year_month,
    c.channel,
    ROUND(SUM(i.spend_usd), 0)           AS total_spend,
    ROUND(SUM(v.order_value_usd), 0)     AS total_revenue,
    ROUND(SAFE_DIVIDE(SUM(v.order_value_usd), SUM(i.spend_usd)), 2) AS roas
FROM `traffic_ad_roi_clean.ad_impressions` i
JOIN `traffic_ad_roi_clean.campaigns`      c ON c.campaign_id = i.campaign_id
JOIN `traffic_ad_roi_clean.conversions`    v ON v.campaign_id = i.campaign_id
WHERE c.channel IN ('Email', 'Google Ads')
GROUP BY 1, 2
ORDER BY 1, 2;

-- A3.1
-- 報告提及 Facebook_Retargeting（ROAS 2.63x）顯著優於 Facebook_Conversion（ROAS 1.04x），
-- 但缺一個從 Session 層面說明兩者受眾行為差異的 SQL（如 engagement_tier 分布、頁面深度、Bounce Rate）
-- Facebook Retargeting vs Conversion：核心效益對比
-- 資料來源：v_campaign_roi（已建立的 View）
SELECT
    campaign_name,
    campaign_type,
    total_orders,
    ROUND(total_spend_usd, 0)                           AS total_spend_usd,
    ROUND(total_revenue_usd, 0)                         AS total_revenue_usd,
    ROUND(ctr * 100, 2)                                 AS ctr_pct,
    ROUND(session_cvr * 100, 2)                         AS cvr_pct,
    ROUND(roas, 2)                                      AS roas,
    ROUND(roi * 100, 1)                                 AS roi_pct,
    ROUND(cost_per_acquisition, 2)                      AS cpa_usd
FROM `traffic_ad_roi_clean.v_campaign_roi`
WHERE channel = 'Facebook Ads'
ORDER BY roas DESC;

-- A3.2
-- 直接從 Session 層面說明兩個 Campaign 吸引的受眾行為品質差異
-- Facebook Retargeting vs Conversion：Session 受眾行為品質分析
SELECT
    c.campaign_name,
    c.campaign_type,

    -- 流量規模
    COUNT(DISTINCT s.session_id)                                            AS total_sessions,

    -- 互動品質
    ROUND(AVG(s.pages_viewed), 2)                                           AS avg_pages_viewed,
    ROUND(AVG(s.session_duration_sec), 0)                                   AS avg_session_duration_sec,
    ROUND(SUM(s.is_bounce) / COUNT(DISTINCT s.session_id) * 100, 2)        AS bounce_rate_pct,

    -- Engagement Tier 分布
    ROUND(COUNTIF(s.engagement_tier = 'High')
          / COUNT(DISTINCT s.session_id) * 100, 2)                         AS high_engagement_pct,
    ROUND(COUNTIF(s.engagement_tier = 'Medium')
          / COUNT(DISTINCT s.session_id) * 100, 2)                         AS medium_engagement_pct,
    ROUND(COUNTIF(s.engagement_tier = 'Low')
          / COUNT(DISTINCT s.session_id) * 100, 2)                         AS low_engagement_pct,

    -- 轉換結果
    COUNT(v.order_id)                                                       AS total_orders,
    ROUND(SAFE_DIVIDE(COUNT(v.order_id),
          COUNT(DISTINCT s.session_id)) * 100, 2)                          AS cvr_pct,
    ROUND(AVG(v.order_value_usd), 2)                                        AS avg_order_value_usd

FROM `traffic_ad_roi_clean.sessions`        s
JOIN `traffic_ad_roi_clean.campaigns`       c  ON c.campaign_id = s.campaign_id
LEFT JOIN `traffic_ad_roi_clean.conversions` v  ON v.session_id  = s.session_id

WHERE c.channel = 'Facebook Ads'
  AND c.campaign_type IN ('Retargeting', 'Conversion')

GROUP BY c.campaign_name, c.campaign_type
ORDER BY cvr_pct DESC;

-- A3.3
-- Facebook Retargeting vs Conversion：消費層級分布
SELECT
    c.campaign_name,
    c.campaign_type,
    v.order_value_tier,
    COUNT(v.order_id)                                                       AS orders,
    ROUND(COUNT(v.order_id)
          / SUM(COUNT(v.order_id)) OVER (PARTITION BY c.campaign_name)
          * 100, 2)                                                         AS tier_pct,
    ROUND(AVG(v.order_value_usd), 2)                                        AS avg_order_value_usd

FROM `traffic_ad_roi_clean.conversions`    v
JOIN `traffic_ad_roi_clean.campaigns`      c ON c.campaign_id = v.campaign_id

WHERE c.channel = 'Facebook Ads'
  AND c.campaign_type IN ('Retargeting', 'Conversion')

GROUP BY c.campaign_name, c.campaign_type, v.order_value_tier
ORDER BY c.campaign_name, avg_order_value_usd DESC;