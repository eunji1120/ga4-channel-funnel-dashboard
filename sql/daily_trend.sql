-- daily_trend
-- One row per date x channel x device with 7-day rolling sums (window functions).
-- Rolling SUMS (not averages) are stored so Looker Studio can re-aggregate them under any
-- channel/device filter: 7-day avg sessions = SUM(sessions_7d) / MAX(days_in_window),
-- 7-day conversion rate = SUM(purchase_sessions_7d) / SUM(sessions_7d).
-- A dense calendar x segment grid makes ROWS BETWEEN 6 PRECEDING mean exactly 7 calendar
-- days, even for segments with no sessions on some days.
-- Feeds the "Daily trend" charts in Looker Studio.

CREATE OR REPLACE VIEW `profound-hydra-512219-h0.ga4_demo.daily_trend` AS
WITH daily AS (
  SELECT
    event_date, channel, device,
    SUM(sessions)          AS sessions,
    SUM(purchase_sessions) AS purchase_sessions,
    SUM(revenue_usd)       AS revenue_usd
  FROM `profound-hydra-512219-h0.ga4_demo.daily_channel_funnel`
  GROUP BY event_date, channel, device
),
segments AS (SELECT DISTINCT channel, device FROM daily),
calendar AS (
  SELECT event_date
  FROM UNNEST(GENERATE_DATE_ARRAY('2020-11-01', '2021-01-31')) AS event_date
),
grid AS (
  SELECT
    c.event_date, s.channel, s.device,
    COALESCE(d.sessions, 0)          AS sessions,
    COALESCE(d.purchase_sessions, 0) AS purchase_sessions,
    COALESCE(d.revenue_usd, 0)       AS revenue_usd
  FROM calendar c
  CROSS JOIN segments s
  LEFT JOIN daily d USING (event_date, channel, device)
)
SELECT
  event_date, channel, device,
  sessions, purchase_sessions, revenue_usd,
  SUM(sessions)          OVER w7 AS sessions_7d,
  SUM(purchase_sessions) OVER w7 AS purchase_sessions_7d,
  COUNT(*)               OVER w7 AS days_in_window   -- < 7 for the first 6 days of the range
FROM grid
WINDOW w7 AS (PARTITION BY channel, device ORDER BY event_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW);
