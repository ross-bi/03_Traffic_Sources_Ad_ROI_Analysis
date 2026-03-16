-- GA4 流量來源 + 轉換彙總
WITH sessions AS (
  SELECT
    trafficSource.medium                          AS channel,
    trafficSource.source                          AS source,
    trafficSource.campaign                        AS campaign_name,
    COUNT(DISTINCT fullVisitorId)                 AS sessions,
    SUM(totals.transactions)                      AS transactions,
    SUM(totals.transactionRevenue) / 1000000      AS revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`
  WHERE _TABLE_SUFFIX BETWEEN '20160801' AND '20170801'
    AND trafficSource.medium IS NOT NULL
  GROUP BY 1, 2, 3
)
SELECT * FROM sessions
ORDER BY revenue DESC;
