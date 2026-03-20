-- ============================================================
-- 04_roi_analysis.sql
-- Q3: 不同廣告活動的 ROI 分析
-- ============================================================

-- ── View 7: Campaign 級別 ROI 總覽 ──────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi_clean.v_campaign_roi` AS
WITH campaign_spend AS (
    SELECT
        campaign_id,
        SUM(spend_usd)     AS total_spend_usd,
        SUM(impressions)   AS total_impressions,
        SUM(clicks)        AS total_clicks,
        ROUND(SAFE_DIVIDE(SUM(clicks), SUM(impressions)), 6) AS overall_ctr
    FROM `traffic_ad_roi_clean.ad_impressions`
    GROUP BY campaign_id
),
campaign_revenue AS (
    SELECT
        campaign_id,
        COUNT(*)               AS total_orders,
        SUM(order_value_usd)   AS total_revenue_usd,
        AVG(order_value_usd)   AS avg_order_value
    FROM `traffic_ad_roi_clean.conversions`
    GROUP BY campaign_id
),
campaign_sessions AS (
    SELECT
        campaign_id,
        COUNT(*)                        AS total_sessions,
        COUNTIF(is_bounce = 0)          AS engaged_sessions
    FROM `traffic_ad_roi_clean.sessions`
    GROUP BY campaign_id
)
SELECT
    c.campaign_id,
    c.campaign_name,
    c.channel,
    c.campaign_type,
    c.daily_budget,
    DATE_DIFF(LEAST(c.end_date, DATE '2024-12-31'), c.start_date, DAY) + 1 AS campaign_days,

    -- Spend & Traffic
    COALESCE(sp.total_spend_usd, 0)    AS total_spend_usd,
    COALESCE(sp.total_impressions, 0)  AS total_impressions,
    COALESCE(sp.total_clicks, 0)       AS total_clicks,
    ROUND(COALESCE(sp.overall_ctr, 0) * 100, 3) AS ctr_pct,

    -- Sessions & Engagement
    COALESCE(se.total_sessions, 0)     AS total_sessions,
    COALESCE(se.engaged_sessions, 0)   AS engaged_sessions,

    -- Conversions & Revenue
    COALESCE(rv.total_orders, 0)       AS total_orders,
    ROUND(COALESCE(rv.total_revenue_usd, 0), 2) AS total_revenue_usd,
    ROUND(COALESCE(rv.avg_order_value, 0), 2)   AS avg_order_value_usd,

    -- CVR
    ROUND(SAFE_DIVIDE(COALESCE(rv.total_orders, 0),
          COALESCE(se.total_sessions, 1)) * 100, 3)  AS session_cvr_pct,

    -- CPA = spend / orders
    ROUND(SAFE_DIVIDE(COALESCE(sp.total_spend_usd, 0),
          NULLIF(COALESCE(rv.total_orders, 0), 0)), 2) AS cost_per_acquisition,

    -- CPM = spend / impressions * 1000
    ROUND(SAFE_DIVIDE(COALESCE(sp.total_spend_usd, 0),
          COALESCE(sp.total_impressions, 1)) * 1000, 2) AS cpm_usd,

    -- CPC = spend / clicks
    ROUND(SAFE_DIVIDE(COALESCE(sp.total_spend_usd, 0),
          NULLIF(COALESCE(sp.total_clicks, 0), 0)), 2) AS cpc_usd,

    -- ROAS = revenue / spend
    ROUND(SAFE_DIVIDE(COALESCE(rv.total_revenue_usd, 0),
          NULLIF(COALESCE(sp.total_spend_usd, 0), 0)), 2) AS roas,

    -- ROI % = (revenue - spend) / spend * 100
    ROUND(SAFE_DIVIDE(
        COALESCE(rv.total_revenue_usd, 0) - COALESCE(sp.total_spend_usd, 0),
        NULLIF(COALESCE(sp.total_spend_usd, 0), 0)
    ) * 100, 2) AS roi_pct

FROM `traffic_ad_roi_clean.campaigns` c
LEFT JOIN campaign_spend   sp ON c.campaign_id = sp.campaign_id
LEFT JOIN campaign_revenue rv ON c.campaign_id = rv.campaign_id
LEFT JOIN campaign_sessions se ON c.campaign_id = se.campaign_id
ORDER BY roi_pct DESC NULLS LAST;


-- ── View 8: 月度 ROI 趨勢（付費渠道）────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi_clean.v_monthly_roi_trend` AS
WITH monthly_spend AS (
    SELECT
        c.channel,
        FORMAT_DATE('%Y-%m', ai.date) AS year_month,
        SUM(ai.spend_usd)             AS spend_usd
    FROM `traffic_ad_roi_clean.ad_impressions` ai
    JOIN `traffic_ad_roi_clean.campaigns` c USING (campaign_id)
    WHERE c.channel NOT IN ('Organic', 'Direct')
    GROUP BY c.channel, year_month
),
monthly_revenue AS (
    SELECT
        channel,
        FORMAT_DATE('%Y-%m', order_date) AS year_month,
        SUM(order_value_usd)             AS revenue_usd
    FROM `traffic_ad_roi_clean.conversions`
    WHERE channel NOT IN ('Organic', 'Direct')
    GROUP BY channel, year_month
)
SELECT
    ms.year_month,
    ms.channel,
    ROUND(ms.spend_usd, 2)             AS spend_usd,
    ROUND(COALESCE(mr.revenue_usd,0),2) AS revenue_usd,
    ROUND(SAFE_DIVIDE(COALESCE(mr.revenue_usd,0), NULLIF(ms.spend_usd,0)), 2) AS roas,
    ROUND(SAFE_DIVIDE(
        COALESCE(mr.revenue_usd,0) - ms.spend_usd,
        NULLIF(ms.spend_usd, 0)
    ) * 100, 2) AS roi_pct
FROM monthly_spend ms
LEFT JOIN monthly_revenue mr
    ON ms.channel = mr.channel AND ms.year_month = mr.year_month
ORDER BY ms.year_month, ms.channel;


-- ── View 9: Campaign Type ROI 比較 ──────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi_clean.v_campaign_type_roi` AS
SELECT
    channel,
    campaign_type,
    COUNT(*)                            AS campaign_count,
    ROUND(SUM(total_spend_usd), 2)      AS total_spend_usd,
    ROUND(SUM(total_revenue_usd), 2)    AS total_revenue_usd,
    ROUND(AVG(ctr_pct), 3)              AS avg_ctr_pct,
    ROUND(AVG(session_cvr_pct), 3)      AS avg_cvr_pct,
    ROUND(AVG(roas), 2)                 AS avg_roas,
    ROUND(AVG(roi_pct), 2)              AS avg_roi_pct,
    ROUND(AVG(cost_per_acquisition), 2) AS avg_cpa_usd
FROM `traffic_ad_roi_clean.v_campaign_roi`
GROUP BY channel, campaign_type
ORDER BY avg_roi_pct DESC;
