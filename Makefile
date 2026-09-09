.PHONY: up down logs dbt-run dbt-test dbt-docs dbt-watch

#override if you use a different venv/install.
DBT ?= ../.venv/Scripts/dbt

up:
	docker compose up --build -d

down:
	docker compose down -v

logs:
	docker compose logs -f emulator

dbt-run:
	cd dbt && $(DBT) run

dbt-test:
	cd dbt && $(DBT) test

dbt-docs:
	cd dbt && $(DBT) docs generate && $(DBT) docs serve

INTERVAL_SECONDS ?= 30
dbt-watch:
	cd dbt && while true; do \
		date -u +"---- dbt build @ %Y-%m-%dT%H:%M:%SZ ----"; \
		$(DBT) build; \
		sleep $(INTERVAL_SECONDS); \
	done
