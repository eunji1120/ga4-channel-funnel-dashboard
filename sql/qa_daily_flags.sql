-- qa_daily_flags
-- Turns the add-to-cart tracking gap into a rule instead of something spotted by eye.
-- A checkout normally follows an add-to-cart, so a day with fewer add-to-cart sessions
-- than checkout sessions is flagged as a likely tracking problem.
-- Feeds the QA page in Looker Studio (red rows + "flagged days" scorecard).

CREATE OR REPLACE VIEW `profound-hydra-512219-h0.ga4_demo.qa_daily_flags` AS
SELECT
  event_date,
  SUM(add_to_cart_sessions) AS add_to_cart_sessions,
  SUM(checkout_sessions)    AS checkout_sessions,
  IF(SUM(add_to_cart_sessions) < SUM(checkout_sessions), 1, 0) AS qa_flag,
  IF(SUM(add_to_cart_sessions) < SUM(checkout_sessions),
     'Add-to-cart below checkout: likely tracking gap', 'OK') AS qa_status
FROM `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel`
GROUP BY event_date;
