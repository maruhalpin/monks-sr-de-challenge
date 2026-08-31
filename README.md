# Senior Data Engineer Challenge — XYZ × .Monks

The business brief and expected deliverables are in [ENUNCIADO.md](ENUNCIADO.md).

This README only covers how to start the local lab (Postgres + emulator).

## Requirements

- Docker Desktop
- Python 3.10+
- `make` (optional; the same commands are listed below)

## Lab

On startup, the emulator loads **May 2026**. For ~10 minutes it then replays **June 2026**: GA4 events as a stream and media data in 6-hour batches (4 records per campaign per day).

```bash
make up          # docker compose up --build -d
make logs        # follow the emulator
```

Wait for the `historical backfill complete` log. From that point, May is queryable. The June stream ends with `live stream complete`.

Connection:

```text
host: localhost
port: 5432
database: xyz
user: xyz
password: xyz
```

Source tables (the only ones dbt should consume):


| Table                         | What it is  |
| ----------------------------- | ----------- |
| `raw.google_analytics_events` | GA4 events  |
| `raw.google_ads`              | Google Ads  |
| `raw.meta_ads`                | Meta Ads    |


To stop the environment and delete the volume:

```bash
make down
```

Do not read the CSVs in `.data`. The contract is Postgres.

## Deliverable B — dbt

Initialize your own dbt project in `dbt/` and point it at the lab Postgres. Model architecture, tests, and docs are part of the evaluation.

## Submission

1. GCP architecture document (deliverable A)
2. A dbt project that compiles and runs against the lab (deliverable B)
3. Answers to the business questions using the simulated data
