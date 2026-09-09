.PHONY: up down logs dbt-run dbt-test dbt-docs dbt-watch

up:
	docker compose up --build -d

down:
	docker compose down -v

logs:
	docker compose logs -f emulator

dbt-run:
	cd dbt && dbt run

dbt-test:
	cd dbt && dbt test

dbt-docs:
	cd dbt && dbt docs generate && dbt docs serve

INTERVAL_SECONDS ?= 30
dbt-watch:
	cd dbt && while true; do \
		date -u +"---- dbt build @ %Y-%m-%dT%H:%M:%SZ ----"; \
		dbt build; \
		sleep $(INTERVAL_SECONDS); \
	done
