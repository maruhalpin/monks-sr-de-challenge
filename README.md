# Desafío Senior Data Engineer — XYZ × .Monks

El enunciado del negocio y los entregables esperados estan en `[ENUNCIADO.md](ENUNCIADO.md)`.

Este README solo cubre cómo levantar el lab local (Postgres + emulador).

## Requisitos

- Docker Desktop
- Python 3.10+
- `make` (opcional; los mismos comandos están más abajo)

## Lab

El emulador carga **mayo 2026** al arrancar y, durante ~10 minutos, reproduce **junio 2026**: eventos GA4 en streaming y data de media en batches de 6 horas (4 registros por campaña por día).

```bash
make up          # docker compose up --build -d
make logs        # seguir el emulador
```

Esperá el log `historical backfill complete`. A partir de ahí mayo ya es consultable. El stream de junio termina con `live stream complete`.

Conexión:

```text
host: localhost
port: 5432
database: xyz
user: xyz
password: xyz
```

Tablas de origen (únicas que debe consumir dbt):


| Tabla                         | Qué es      |
| ----------------------------- | ----------- |
| `raw.google_analytics_events` | Eventos GA4 |
| `raw.google_ads`              | Google Ads  |
| `raw.meta_ads`                | Meta Ads    |


Para bajar el entorno y borrar el volumen:

```bash
make down
```

No leas los CSV de `.data`. El contrato es Postgres.

## Entregable B — dbt

Inicializá tu propio proyecto dbt en `dbt/` y conectalo al Postgres del laboratorio. La arquitectura de modelos, tests y docs es parte de lo que se evalúa.

## Entrega

1. Documento de arquitectura GCP (entregable A)
2. Proyecto dbt que compile y corra utilizando el lab(entregable B)
3. Respuestas a las preguntas de negocio utilizando la data que se simula.

