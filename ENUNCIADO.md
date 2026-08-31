# Senior Data Engineer Challenge — XYZ × .Monks

## Context

XYZ is a fashion retail company. To grow the business, they run digital marketing campaigns, mainly on Meta and Google Ads.

To understand user behavior on their website, analyze the most visited pages, and evaluate the purchase funnel, they implemented Google Analytics 4 (GA4).

This year, XYZ formalized a strategic partnership with .Monks after parting ways with their previous agency for not delivering the expected results.

XYZ’s Director of Marketing and Analytics is the main stakeholder for this project.

## Current ecosystem

The kickoff meeting described a **hybrid** setup:


| Source     | Table                    | Cadence                                      | Grain                |
| ---------- | ------------------------ | -------------------------------------------- | -------------------- |
| GA4        | `google_analytics_table` | Continuous streaming (GA4 export → BigQuery) | Event                |
| Google Ads | `google_ads_table`       | Batch every 6 hours (4 loads per day)        | Campaign × 6h window |
| Meta Ads   | `meta_ads_table`         | Batch every 6 hours (4 loads per day)        | Campaign × 6h window |


Media windows are `00:00–06:00`, `06:00–12:00`, `12:00–18:00`, and `18:00–24:00`. Each campaign produces **4 records per day** (one per batch).

### Google Ads


| Column          | Description                          |
| --------------- | ------------------------------------ |
| `date`          | Report date                          |
| `campaign_name` | Campaign name                        |
| `campaign_id`   | Campaign identifier (prefix `GADS_`) |
| `placement_id`  | Ad placement                         |
| `account_id`    | Ads account                          |
| `account_name`  | Account name                         |
| `country`       | Country                              |
| `clicks`        | Clicks in the window                 |
| `impressions`   | Impressions in the window            |
| `spend`         | Spend in the window                  |




### Meta Ads


| Column          | Description                              |
| --------------- | ---------------------------------------- |
| `date`          | Report date                              |
| `campaign_name` | Campaign name                            |
| `campaign_id`   | Campaign identifier (prefix `META_`)     |
| `ad_location`   | Ad location (Feed, Stories, Reels, etc.) |
| `account_id`    | Ads account                              |
| `account_name`  | Account name                             |
| `country`       | Country                                  |
| `clicks`        | Clicks in the window                     |
| `impressions`   | Impressions in the window                |
| `spend`         | Spend in the window                      |




### Google Analytics 4


| Column            | Description                                |
| ----------------- | ------------------------------------------ |
| `user_id`         | User                                       |
| `session_id`      | Session (unique together with `user_id`)   |
| `event_timestamp` | Event timestamp (epoch ms)                 |
| `event_name`      | Event name (`page_view`, `purchase`, etc.) |
| `event_params`    | Event parameters (JSON)                    |
| `campaign_id`     | Attribution campaign when present          |
| `stream_name`     | GA4 stream                                 |
| `page_url`        | Page URL                                   |
| `country`         | Country                                    |
| `is_conversion`   | Conversion flag                            |




## Business questions

At the end of the session, the Director raised the following questions. The data team must be able to answer them in a scalable way:

1. **Multichannel performance and investment.** Which advertising platform offers the best financial efficiency and overall performance across key funnel metrics (ROI, CPC, CPA, etc.)?
2. **Campaign attribution and effectiveness.** Which specific campaigns are driving the highest volume of conversions and revenue?
3. **Acquisition channel analysis.** Which traffic channels perform best overall when on-site user behavior is combined with advertising spend?
4. **Data model and architecture design.** Which data model and intermediate/final tables should be designed to power the reports? How should these business needs be translated into clear technical specs for the data engineering team?

The .Monks technical lead is asking you for an action plan for the internal team: client needs, required transformations, and how to model the solution.

---

The challenge has **two independent deliverables**. BigQuery is not evaluated in the hands-on work, and Postgres is not evaluated in the theoretical design.

## Deliverable A  - Theoretical design (GCP)

Architecture. Deliver a document (and a diagram) describing how you would solve this problem **on Google Cloud**, where the GA4 streaming data will land in **BigQuery**, and the media data (Meta and Google Ads) will land in **Google Cloud Storage**.

You must cover:

- Data manipulation (GA4 streaming vs. Ads 6h batch), tools, and error handling.
- Streaming–batch coupling: late-arriving data, watermarks, reprocessing.
- Architecture to understand how to move data from one place to another.
- How the final tables are consumed to answer the questions.

Nothing needs to be implemented in GCP for this exercise, only design.

## Deliverable B - Implementation (dbt + Postgres)

Implement the data model with **dbt** on **Postgres**. The lab emulates the hybrid setup:

- When the environment starts, **historical data** is already loaded (May 2026).
- For ~10 minutes, GA4 events keep arriving (streaming) along with Google Ads and Meta batches (a compressed equivalent of a load every 6 hours).
- Media tables have **4 records per campaign per day**. The sum of those 4 records is the daily total.

Consume only the `raw` tables in Postgres (not the source CSVs). You must:

- Model following dbt best practices
- Solve the streaming–batch integration incrementally (watermarks, incomplete windows, deduplication)
- Join event/session (GA4) with campaign × 6h window (Ads)
- Answer ROI, CPC, CPA, conversions, attribution, and revenue accurately
- Include tests
- Return partial results while the system is on *(for example, run dbt every x amount of seconds, emulating a cron job)*

Lab setup instructions are in the `README`.