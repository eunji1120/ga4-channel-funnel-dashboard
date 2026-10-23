-- qa_raw_event_check
-- Source check for the add-to-cart tracking gap, run directly on the raw GA4 export
-- (no view in between). Counts events per day for November 2020.
-- Result: add_to_cart is 0 on Nov 2-15 and Nov 21-24 (4 on Nov 1, 15 on Nov 20)
-- while begin_checkout continues normally, so the gap is in the source data,
-- not in the daily_channel_funnel view.

SELECT
  PARSE_DATE('%Y%m%d', event_date) AS date,
  COUNTIF(event_name = 'add_to_cart')    AS add_to_cart_events,
  COUNTIF(event_name = 'begin_checkout') AS checkout_events
FROM `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*`
WHERE _TABLE_SUFFIX BETWEEN '20201101' AND '20201130'
GROUP BY date
ORDER BY date;
