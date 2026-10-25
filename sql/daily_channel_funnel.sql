-- daily_channel_funnel
-- Turns raw GA4 events into one row per date x channel (medium/source) x device,
-- with session counts at each funnel step and purchase revenue.
-- Source: bigquery-public-data.ga4_obfuscated_sample_ecommerce (Nov 2020 - Jan 2021)
--
-- Step 1 materialises the model as a table: the sample never changes, so scanning the
-- ~1 GB raw export once is enough. Step 2 keeps the reporting view name that Looker Studio
-- and the other views use, so nothing downstream has to be reconnected.
-- Known limit: sessions are counted per day, so the 845 sessions (0.23%) that cross
-- midnight are counted on both days; conversion rate moves by 0.002 points.

-- Step 1: model table
CREATE OR REPLACE TABLE `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel_tbl` AS
WITH events AS (
  SELECT
    PARSE_DATE('%Y%m%d', event_date) AS event_date,
    traffic_source.medium AS medium,
    traffic_source.source AS source,
    -- Business-friendly channel name (naming convention lives in the model, not the report)
    CASE traffic_source.medium
      WHEN 'organic'        THEN 'Organic search'
      WHEN 'cpc'            THEN 'Paid search (cpc)'
      WHEN 'referral'       THEN 'Referral'
      WHEN '(none)'         THEN 'Direct (none)'
      WHEN '(data deleted)' THEN 'Data deleted (sample)'
      WHEN '<Other>'        THEN 'Other (grouped in sample)'
      ELSE traffic_source.medium
    END AS channel,
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
  channel,
  device,
  COUNT(DISTINCT session_id) AS sessions,
  COUNT(DISTINCT IF(event_name = 'view_item',      session_id, NULL)) AS view_item_sessions,
  COUNT(DISTINCT IF(event_name = 'add_to_cart',    session_id, NULL)) AS add_to_cart_sessions,
  COUNT(DISTINCT IF(event_name = 'begin_checkout', session_id, NULL)) AS checkout_sessions,
  COUNT(DISTINCT IF(event_name = 'purchase',       session_id, NULL)) AS purchase_sessions,
  SUM(IF(event_name = 'purchase', revenue, 0)) AS revenue_usd
FROM events
GROUP BY event_date, medium, source, channel, device;

-- Step 2: reporting view used by Looker Studio, daily_trend and qa_daily_flags
CREATE OR REPLACE VIEW `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel` AS
SELECT * FROM `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel_tbl`;
