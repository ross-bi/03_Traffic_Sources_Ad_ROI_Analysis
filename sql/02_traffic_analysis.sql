-- ============================================================
-- 02_traffic_analysis.sql
-- Q1: 哪些流量來源帶來最多轉換？
-- ============================================================

-- ── View 1: 各渠道整體表現摘要 ───────────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_channel_performance` AS
WITH session_stats AS (
    SELECT
        channel,
        COUNT(*)                                           AS total_sessions,
        COUNTIF(is_bounce = 1)                             AS bounced_sessions,
        ROUND(COUNTIF(is_bounce = 1) / COUNT(*), 4)        AS bounce_rate,
        ROUND(AVG(session_duration_sec), 1)                AS avg_duration_sec,
        ROUND(AVG(pages_viewed), 2)                        AS avg_pages
    FROM `traffic_ad_roi.sessions`
    GROUP BY channel
),
conversion_stats AS (
    SELECT
        channel,
        COUNT(*)                                           AS total_orders,
        ROUND(SUM(order_value_usd), 2)                     AS total_revenue_usd,
        ROUND(AVG(order_value_usd), 2)                     AS avg_order_value_usd
    FROM `traffic_ad_roi.conversions`
    GROUP BY channel
),
spend_stats AS (
    SELECT
        c.channel,
        ROUND(SUM(ai.spend_usd), 2)                        AS total_spend_usd
    FROM `traffic_ad_roi.ad_impressions` ai
    JOIN `traffic_ad_roi.campaigns` c USING (campaign_id)
    GROUP BY c.channel
)
SELECT
    s.channel,
    s.total_sessions,
    s.bounced_sessions,
    s.bounce_rate,
    s.avg_duration_sec,
    s.avg_pages,
    COALESCE(cv.total_orders, 0)                               AS total_orders,
    COALESCE(cv.total_revenue_usd, 0)                          AS total_revenue_usd,
    COALESCE(cv.avg_order_value_usd, 0)                        AS avg_order_value_usd,
    COALESCE(sp.total_spend_usd, 0)                            AS total_spend_usd,
    -- Conversion Rate = orders / sessions
    ROUND(SAFE_DIVIDE(COALESCE(cv.total_orders, 0), s.total_sessions), 4) AS conversion_rate,
    -- CPA = spend / orders
    ROUND(SAFE_DIVIDE(COALESCE(sp.total_spend_usd, 0), COALESCE(cv.total_orders, 0)), 2) AS cost_per_acquisition,
    -- ROAS = revenue / spend
    ROUND(SAFE_DIVIDE(COALESCE(cv.total_revenue_usd, 0), COALESCE(sp.total_spend_usd, 0)), 2) AS roas
FROM session_stats s
LEFT JOIN conversion_stats cv ON s.channel = cv.channel
LEFT JOIN spend_stats sp      ON s.channel = sp.channel
ORDER BY total_orders DESC;


-- ── View 2: 月度渠道趨勢 ─────────────────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_monthly_channel_trend` AS
SELECT
    FORMAT_DATE('%Y-%m', order_date)   AS year_month,
    channel,
    COUNT(*)                           AS orders,
    ROUND(SUM(order_value_usd), 2)     AS revenue_usd
FROM `traffic_ad_roi.conversions`
GROUP BY year_month, channel
ORDER BY year_month, channel;


-- ── View 3: 裝置 × 渠道轉換分布 ─────────────────────────────────
CREATE OR REPLACE VIEW `traffic_ad_roi.v_device_channel_conversion` AS
SELECT
    channel,
    device,
    COUNT(*)                       AS orders,
    ROUND(SUM(order_value_usd),2)  AS revenue_usd,
    ROUND(AVG(order_value_usd),2)  AS avg_order_value
FROM `traffic_ad_roi.conversions`
GROUP BY channel, device
ORDER BY channel, orders DESC;
