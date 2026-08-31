# Desafío Senior Data Engineer — XYZ × .Monks

## Contexto

La empresa XYZ se dedica a la venta minorista de artículos de moda. Para impulsar su negocio, realizan campañas de marketing digital, principalmente en Meta y Google Ads.

Con el objetivo de comprender el comportamiento de los usuarios en su sitio web, analizar las páginas más visitadas y evaluar la efectividad del funnel de compra, implementaron Google Analytics 4 (GA4).

Durante este año, XYZ decidió formalizar una alianza estratégica con .Monks, tras desvincularse de su agencia anterior por no alcanzar los resultados esperados.

El Director de Marketing y Analytics de XYZ es el principal stakeholder de este proyecto.

## Ecosistema actual

En la reunión inicial se presentó un esquema **híbrido**:


| Fuente     | Tabla                    | Cadencia                                        | Grano                   |
| ---------- | ------------------------ | ----------------------------------------------- | ----------------------- |
| GA4        | `google_analytics_table` | Streaming continuo (exportación GA4 → BigQuery) | Evento                  |
| Google Ads | `google_ads_table`       | Batch cada 6 horas (4 cargas por día)           | Campaña × ventana de 6h |
| Meta Ads   | `meta_ads_table`         | Batch cada 6 horas (4 cargas por día)           | Campaña × ventana de 6h |


Las ventanas de media son `00:00–06:00`, `06:00–12:00`, `12:00–18:00` y `18:00–24:00`. Cada campaña genera **4 registros por día** (uno por batch).

### Google Ads


| Columna         | Descripción                                |
| --------------- | ------------------------------------------ |
| `date`          | Fecha del reporte                          |
| `campaign_name` | Nombre de la campaña                       |
| `campaign_id`   | Identificador de campaña (prefijo `GADS_`) |
| `placement_id`  | Placement del anuncio                      |
| `account_id`    | Cuenta de anuncios                         |
| `account_name`  | Nombre de la cuenta                        |
| `country`       | País                                       |
| `clicks`        | Clics en la ventana                        |
| `impressions`   | Impresiones en la ventana                  |
| `spend`         | Inversión en la ventana                    |




### Meta Ads


| Columna         | Descripción                                        |
| --------------- | -------------------------------------------------- |
| `date`          | Fecha del reporte                                  |
| `campaign_name` | Nombre de la campaña                               |
| `campaign_id`   | Identificador de campaña (prefijo `META_`)         |
| `ad_location`   | Ubicación del anuncio (Feed, Stories, Reels, etc.) |
| `account_id`    | Cuenta de anuncios                                 |
| `account_name`  | Nombre de la cuenta                                |
| `country`       | País                                               |
| `clicks`        | Clics en la ventana                                |
| `impressions`   | Impresiones en la ventana                          |
| `spend`         | Inversión en la ventana                            |




### Google Analytics 4


| Columna           | Descripción                                       |
| ----------------- | ------------------------------------------------- |
| `user_id`         | Usuario                                           |
| `session_id`      | Sesión (único junto con `user_id`)                |
| `event_timestamp` | Timestamp del evento (epoch ms)                   |
| `event_name`      | Nombre del evento (`page_view`, `purchase`, etc.) |
| `event_params`    | Parámetros del evento (JSON)                      |
| `campaign_id`     | Campaña de atribución cuando está presente        |
| `stream_name`     | Stream de GA4                                     |
| `page_url`        | URL de la página                                  |
| `country`         | País                                              |
| `is_conversion`   | Flag de conversión                                |




## Preguntas de negocio

Al finalizar la sesión, el Director plantea las siguientes interrogantes. El equipo de datos debe poder responderlas de forma escalable:

1. **Rendimiento e inversión multicanal.** ¿Qué plataforma publicitaria ofrece la mejor eficiencia financiera y rendimiento integral considerando las métricas clave del funnel (ROI, CPC, CPA, etc.)?
2. **Atribución y efectividad de campañas.** ¿Qué campañas específicas están impulsando el mayor volumen de conversiones y generación de ingresos?
3. **Análisis de canales de adquisición.** ¿Qué canales de tráfico muestran el mejor desempeño global al integrar el comportamiento del usuario en el sitio con las inversiones publicitarias?
4. **Diseño de modelo de datos y arquitectura.** ¿Qué modelo de datos y tablas intermedias/finales se deben diseñar para alimentar los reportes? ¿Cómo traducir estas necesidades de negocio a especificaciones técnicas claras para el equipo de data engineering?

El líder técnico de .Monks te pide un plan de acción para el equipo interno: necesidades del cliente, transformaciones requeridas y cómo modelar la solución.

---

El desafío tiene **dos entregables independientes**. No se evalúa BigQuery en el desarrollo practico, ni Postgres en el diseño teórico.

## Entregable A — Diseño teórico (GCP)

Arquitectura. Entregar un documento (y un diagrama) que describa cómo resolverías este problema **en Google Cloud**, como si el destino real fuera BigQuery.

Debes cubrir:

- Flujo de datos (GA4 streaming vs. Ads batch 6h), herramientas y manejo de errores
- Particionado, clustering, costos de slots y estrategia de cadencia en BigQuery (como se actualiza la data)
- Acoplamiento streaming–batch: late-arriving data, watermarks, reprocesamiento y JOINs temporales
- Cómo las tablas finales son consumidas para responder las consultas.

No se implementa nada en GCP en este ejercicio, solo teoria.

## Entregable B — Implementación (dbt + Postgres)

Implementar el modelo de datos con **dbt** sobre **Postgres**. El lab emula el esquema híbrido:

- Al levantar el entorno hay **datos históricos** ya cargados (mayo 2026).
- Durante ~10 minutos siguen llegando eventos GA4 (streaming) y batches de Google Ads y Meta (equivalente comprimido a una carga cada 6 horas).
- Las tablas de Media seran de **4 registros por campaña por día**. La sumatoria de los 4 registros sera el total del dia.

Consumir únicamente las tablas `raw` de Postgres (no los CSV de origen). Y se debe:

- Modelar siguiendo las buenas practicas de dbt.
- Resolver la integración streaming–batch de forma incremental (watermarks, ventanas incompletas, deduplicación)
- Unir evento/sesión (GA4) con campaña × ventana de 6h (Ads)
- Responder con precisión las preguntas de ROI, CPC, CPA, conversiones, atribución e ingresos
- Inclucion de tests

Las instrucciones para levantar el lab se documentarán en el `README`.