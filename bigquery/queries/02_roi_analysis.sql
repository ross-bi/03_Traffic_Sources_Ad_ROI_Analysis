WITH ga4_traffic AS (
  SELECT
    trafficSource.medium      AS channel,
    trafficSource.campaign    AS campaign_name,
    COUNT(DISTINCT fullVisitorId)            AS sessions,
    SUM(totals.transactions)                 AS conversions,
    SUM(totals.transactionRevenue) / 1000000 AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
  GROUP BY 1, 2
),
ad_data AS (
  SELECT
    channel,
    campaign_name,
    ad_spend,
    impressions,
    clicks,
    ROUND(clicks / impressions * 100, 2) AS ctr_pct
  FROM `your_project.traffic_roi.ad_campaigns`
)
SELECT
  g.channel,
  g.campaign_name,
  g.sessions,
  g.conversions,
  g.revenue,
  a.ad_spend,
  a.impressions,
  a.clicks,
  a.ctr_pct,
  ROUND((g.revenue - a.ad_spend) / NULLIF(a.ad_spend, 0) * 100, 2) AS roi_pct,
  ROUND(g.revenue / NULLIF(a.ad_spend, 0), 2)                       AS roas
FROM ga4_traffic g
LEFT JOIN ad_data a
  ON LOWER(g.channel) = LOWER(a.channel)
  AND LOWER(g.campaign_name) = LOWER(a.campaign_name)
ORDER BY roi_pct DESC;
