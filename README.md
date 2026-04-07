<!-- Welcome to your new dbt project!

### Using the starter project

Try running the following commands:
- dbt run
- dbt test


### Resources:
- Learn more about dbt [in the docs](https://docs.getdbt.com/docs/introduction)
- Check out [Discourse](https://discourse.getdbt.com/) for commonly asked questions and answers
- Join the [chat](https://community.getdbt.com/) on Slack for live discussions and support
- Find [dbt events](https://events.getdbt.com) near you
- Check out [the blog](https://blog.getdbt.com/) for the latest news on dbt's development and best practices -->

# Franchise Performance Intelligence Agent
### Snowflake Cortex · dbt CLI · Tasty Bytes

A Cortex Agent that answers natural-language questions about franchise performance by combining **structured revenue data** (Cortex Analyst) with **AI-generated unstructured feedback text** (Cortex Search) — all built on the Snowflake Tasty Bytes sample dataset.

> Ask things like: *"Which franchise has low revenue AND complaints about wait times?"* — and get a single, synthesised answer from both your SQL mart and your text feedback index.

---

## Why this project is unique

Most Cortex Agent tutorials wire two pre-existing data sources together. This project adds a third dimension: **using `AI_COMPLETE` to generate realistic franchise feedback text** from real performance metrics, then indexing that text in Cortex Search. It demonstrates the full modern data stack in one end-to-end workflow:

```
dbt (transform) → AI_COMPLETE (enrich) → Cortex Search (index)
                                        → Cortex Analyst (query)
                                        → Cortex Agent (orchestrate)
```

---

## Tech stack

| Layer | Tool |
|---|---|
| Transformation | dbt CLI (Snowflake adapter) |
| Data platform | Snowflake (Tasty Bytes — `tb_101`) |
| LLM enrichment | Snowflake `AI_COMPLETE` (Mistral Large 2) |
| Semantic search | Snowflake Cortex Search |
| NL → SQL | Snowflake Cortex Analyst |
| Orchestration | Snowflake Cortex Agent |
| Chat interface | Snowflake Intelligence UI |

---

## Architecture

```
tb_101.raw_pos
├── franchise
├── truck
├── order_header
├── order_detail
├── menu
└── location
       │
       ▼
┌──────────────────────────────┐
│  Phase 1 — dbt models        │
│  stg_franchise.sql           │
│  stg_order_header.sql        │
│  fct_franchise_revenue.sql   │  ← structured mart
└──────────────┬───────────────┘
               │
               ▼
┌──────────────────────────────┐
│  Phase 2 — AI_COMPLETE       │
│  franchise_perf_summary view │
│  franchise_feedback table    │  ← synthetic text generated per franchise
└──────────────┬───────────────┘
               │
       ┌───────┴────────┐
       ▼                ▼
┌──────────────┐  ┌──────────────────────┐
│ Phase 3      │  │ Phase 4              │
│ Cortex       │  │ Semantic model YAML  │
│ Search       │  │ for Cortex Analyst   │
│ Service      │  └──────────┬───────────┘
└──────┬───────┘             │
       └─────────┬───────────┘
                 ▼
┌──────────────────────────────┐
│  Phase 5 — Cortex Agent      │
│  franchise_intelligence_agent│
│  Routes: Analyst vs Search   │
│  or both for cross-domain Qs │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│  Phase 6 — Snowflake         │
│  Intelligence chat UI        │
└──────────────────────────────┘
```

---

## Prerequisites

- Snowflake trial account with Tasty Bytes loaded (`tb_101` database)
- dbt CLI installed (`pip install dbt-snowflake`)
- Role: `tb_data_engineer` (or `accountadmin` for agent creation)
- Warehouse: `tb_de_wh`
- Cortex AI enabled on your account (enabled by default on trial accounts in US regions)

---

## Project structure

```
tasty_franchise_agent/
├── README.md
├── dbt_project.yml
├── profiles.yml
├── models/
│   ├── staging/
│   │   ├── _sources.yml
│   │   ├── stg_franchise.sql
│   │   └── stg_order_header.sql
│   └── marts/
│       └── fct_franchise_revenue.sql
├── sql/
│   ├── 01_franchise_perf_summary.sql
│   ├── 02_generate_feedback.sql
│   ├── 03_cortex_search_service.sql
│   ├── 04_upload_semantic_model.sql
│   └── 05_create_agent.sql
└── semantic_models/
    └── franchise_revenue_semantic_model.yaml
```

Dataset: Snowflake Tasty Bytes (fictitious food truck company).
