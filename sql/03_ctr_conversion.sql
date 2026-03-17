-- ============================================================
-- 03_ctr_conversion.sql
-- Q2: 廣告 CTR 與訂單轉換率的關聯性
-- ============================================================

-- ── View 4: Campaign 日級別 CTR vs 轉換率 ───────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_campaign_daily_ctr_cvr` AS
WITH daily_impressions AS (
    SELECT
        campaign_id,
        date,
        impressions,
        clicks,
        ctr,
        spend_usd
    FROM `traffic_ad_roi.ad_impressions`
    WHERE clicks > 0
),
daily_sessions AS (
    SELECT
        campaign_id,
        session_date AS date,
        COUNT(*)     AS sessions
    FROM `traffic_ad_roi.sessions`
    GROUP BY campaign_id, session_date
),
daily_conversions AS (
    SELECT
        campaign_id,
        order_date AS date,
        COUNT(*)                       AS orders,
        SUM(order_value_usd)           AS revenue_usd
    FROM `traffic_ad_roi.conversions`
    GROUP BY campaign_id, order_date
)
SELECT
    di.campaign_id,
    c.campaign_name,
    c.channel,
    c.campaign_type,
    di.date,
    di.impressions,
    di.clicks,
    di.ctr,
    di.spend_usd,
    COALESCE(ds.sessions, 0)                                              AS sessions,
    COALESCE(dc.orders, 0)                                                AS orders,
    COALESCE(dc.revenue_usd, 0)                                           AS revenue_usd,
    -- Session CVR = orders / sessions
    ROUND(SAFE_DIVIDE(COALESCE(dc.orders, 0), COALESCE(ds.sessions, 1)), 6) AS session_cvr,
    -- Click CVR = orders / clicks
    ROUND(SAFE_DIVIDE(COALESCE(dc.orders, 0), di.clicks), 6)              AS click_cvr
FROM daily_impressions di
JOIN `traffic_ad_roi.campaigns` c USING (campaign_id)
LEFT JOIN daily_sessions ds      ON di.campaign_id = ds.campaign_id AND di.date = ds.date
LEFT JOIN daily_conversions dc   ON di.campaign_id = dc.campaign_id AND di.date = dc.date
ORDER BY di.date, di.campaign_id;


-- ── View 5: CTR 分層分析（Bucket Analysis）──────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_ctr_bucket_analysis` AS
WITH bucketed AS (
    SELECT
        *,
        CASE
            WHEN ctr < 0.01  THEN '01_CTR < 1%'
            WHEN ctr < 0.02  THEN '02_CTR 1-2%'
            WHEN ctr < 0.03  THEN '03_CTR 2-3%'
            WHEN ctr < 0.04  THEN '04_CTR 3-4%'
            WHEN ctr < 0.05  THEN '05_CTR 4-5%'
            ELSE                  '06_CTR >= 5%'
        END AS ctr_bucket
    FROM `traffic_ad_roi.v_campaign_daily_ctr_cvr`
    WHERE clicks > 0
)
SELECT
    ctr_bucket,
    COUNT(*)                          AS record_count,
    ROUND(AVG(ctr) * 100, 2)          AS avg_ctr_pct,
    ROUND(AVG(session_cvr) * 100, 2)  AS avg_session_cvr_pct,
    ROUND(AVG(click_cvr) * 100, 2)    AS avg_click_cvr_pct,
    ROUND(SUM(orders), 0)             AS total_orders,
    ROUND(SUM(revenue_usd), 2)        AS total_revenue_usd,
    ROUND(AVG(spend_usd), 2)          AS avg_daily_spend_usd
FROM bucketed
GROUP BY ctr_bucket
ORDER BY ctr_bucket;


-- ── View 6: Campaign 匯總 CTR & CVR 散點圖資料 ──────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_campaign_ctr_cvr_scatter` AS
SELECT
    campaign_id,
    campaign_name,
    channel,
    campaign_type,
    ROUND(AVG(ctr) * 100, 3)          AS avg_ctr_pct,
    ROUND(AVG(session_cvr) * 100, 3)  AS avg_session_cvr_pct,
    ROUND(AVG(click_cvr) * 100, 3)    AS avg_click_cvr_pct,
    SUM(impressions)                  AS total_impressions,
    SUM(clicks)                       AS total_clicks,
    SUM(orders)                       AS total_orders,
    ROUND(SUM(revenue_usd), 2)        AS total_revenue_usd,
    ROUND(SUM(spend_usd), 2)          AS total_spend_usd
FROM `traffic_ad_roi.v_campaign_daily_ctr_cvr`
GROUP BY campaign_id, campaign_name, channel, campaign_type
ORDER BY avg_ctr_pct DESC;
