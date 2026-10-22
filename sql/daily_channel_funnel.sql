-- daily_channel_funnel
-- Turns raw GA4 events into one row per date x channel (medium/source) x device,
-- with session counts at each funnel step and purchase revenue.
-- Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce (Nov 2020 - Jan 2021)
-- Feeds the Looker Studio dashboard.

CREATE OR REPLACE VIEW `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel` AS
WITH events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    traffic_source.medium AS medium,
    traffic_source.source AS source,
    device.category AS device,
    -- A GA4 session = user_pseudo_id + ga_session_id
    CONCAT(
      user_pseudo_id, '-',
      CAST((SELECT value.int_value FROM UNNEST(event_params) WHERE key = 'ga_session_id') AS STRING)
    ) AS session_id,
    event_name,
    ecommerce.purchase_revenue_in_usd AS revenue
  FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
  WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20210131'
)
SELECT
  event_date,
  medium,
  source,
  device,
  COUNT(DISTINCT session_id) AS sessions,
  COUNT(DISTINCT IF(event_name = 'view_item',      session_id, NULL)) AS view_item_sessions,
  COUNT(DISTINCT IF(event_name = 'add_to_cart',    session_id, NULL)) AS add_to_cart_sessions,
  COUNT(DISTINCT IF(event_name = 'begin_checkout', session_id, NULL)) AS checkout_sessions,
  COUNT(DISTINCT IF(event_name = 'purchase',       session_id, NULL)) AS purchase_sessions,
  SUM(IF(event_name = 'purchase', revenue, 0)) AS revenue_usd
FROM events
GROUP BY event_date, medium, source, device;
