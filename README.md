# GA4 Channel & Funnel Dashboard (BigQuery + Looker Studio)

A marketing performance dashboard built on Google's public GA4 e-commerce sample data
(Google Merchandise Store, Nov 2020 to Jan 2021). Raw GA4 events are modelled in a
BigQuery SQL view, then reported in Looker Studio with KPI scorecards, a channel
breakdown, a funnel by device, and a daily QA check.

**Live dashboard (public, no sign-in needed):**
<https://datastudio.google.com/reporting/cd440243-4dd2-4a16-b026-54507dded7ab>

![Dashboard overview](screenshots/dashboard_overview.png)

---

## Audience and questions

This is a self-directed portfolio project. I designed it for an **account manager
preparing for a client call** who needs to answer two questions in under a minute:

1. Which channels and devices bring sessions and revenue?
2. Where does the purchase funnel drop off?

## Data and pipeline

| Layer | Details |
| --- | --- |
| Source | `bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_*` (raw GA4 event export) |
| Date range | 2020-11-01 to 2021-01-31 |
| Model | BigQuery view [`sql/daily_channel_funnel.sql`](sql/daily_channel_funnel.sql) |
| Grain | One row per date x channel (medium, source) x device |
| Report | Looker Studio, connected directly to the view |

**How the view works**

- A CTE pulls the date, traffic medium/source, device category, event name and purchase
  revenue from each raw event.
- A session ID is built from `user_pseudo_id` + `ga_session_id`, which is unnested from
  `event_params`.
- The outer query counts distinct sessions overall and at each funnel step
  (`view_item`, `add_to_cart`, `begin_checkout`, `purchase`), and sums purchase revenue.

## Dashboard components

| Component | Purpose |
| --- | --- |
| KPI scorecards | Sessions (360,974), Purchase sessions (4,851), Revenue ($362,165), Conversion Rate (1.34%) |
| Daily trend (dual axis) | Sessions vs purchase sessions over time |
| Revenue by first-user channel | Bar chart sorted high to low (see attribution note below) |
| Funnel steps by device | Viewed item, Added to cart, Checkouts, Purchase sessions for desktop / mobile / tablet |
| Filters | Date range and first-user channel (medium) |
| Daily QA check | Added-to-cart vs checkouts by day, to catch tracking problems |

## Design choices

- **Headline first.** KPI cards sit at the top so the main numbers can be read in seconds.
- **One definition per metric.** Conversion Rate is a single calculated field,
  `SUM(purchase_sessions) / SUM(sessions)`, so every chart uses the same definition.
- **Business-friendly names.** Raw fields are renamed (e.g. `add_to_cart_sessions` becomes
  "Added to cart") and revenue is formatted as full USD figures instead of compact numbers.
- **Self-serve filters.** Date and channel controls let readers answer follow-up questions
  without a new request.
- **Data quality is visible.** Known data issues are noted on the page itself (see below).
- **Honest attribution labels.** In the GA4 BigQuery export, `traffic_source.medium` is the channel that
  *first acquired the user*, not the channel of each session. The chart and filter are therefore labelled
  "First-user channel". For a client report, the attribution view should be agreed with the account team first.

## Data quality finding

While checking the funnel against the source data, I found that **add-to-cart events are
missing or near zero on Nov 1-15 and Nov 20-24, 2020, while checkouts continue normally**.
Since a checkout normally follows an add-to-cart, this points to a tracking gap in the
source data rather than real customer behaviour.

**Source check.** To rule out an error in my own view, I re-counted the events directly in the raw GA4
export with [`sql/qa_raw_event_check.sql`](sql/qa_raw_event_check.sql) (no view in between):

| Date (2020) | add_to_cart events | begin_checkout events |
| --- | ---: | ---: |
| Nov 1 | 4 | 127 |
| Nov 2–15 | 0 every day | 132–605 per day |
| Nov 16 | 85 | 542 |
| Nov 17 | 535 | 693 |
| Nov 20 | 15 | 318 |
| Nov 21–24 | 0 every day | 166–366 per day |
| Nov 26 | 1,047 | 321 |

The gap is present in the source itself, so it is not caused by the view's logic.

I did not patch or estimate the missing values. Instead, the dashboard:

- includes a **Daily QA check** table that makes the gap easy to see, and
- carries a **data quality note** explaining that the "Added to cart" step is understated
  for those 20 days.

In a production setting, I would escalate this to the team that owns conversion tracking,
with the affected dates and the query that shows the gap.

![Daily QA check](screenshots/qa_check_tracking_gap.png)

## Repository structure

```text
.
├── README.md
├── sql/
│   ├── daily_channel_funnel.sql   # BigQuery view feeding the dashboard
│   └── qa_raw_event_check.sql     # source check on the raw GA4 export
└── screenshots/
    ├── dashboard_overview.png
    └── qa_check_tracking_gap.png
```

## Reproduce

1. Open the BigQuery console (the free sandbox works) and create a dataset.
2. Run [`sql/daily_channel_funnel.sql`](sql/daily_channel_funnel.sql), replacing the
   project and dataset name with your own.
3. In Looker Studio, add a BigQuery data source pointing at the view and build the charts.

---

*Data: Google's public GA4 obfuscated sample e-commerce dataset. Built by Eun Ji (Holly) Hwang.*
