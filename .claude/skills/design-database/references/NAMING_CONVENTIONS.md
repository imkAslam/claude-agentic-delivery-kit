# Database naming conventions

Consistency matters more than any particular style. If the project's ORM or framework has a strong convention, follow it and record that in DATA-MODEL §Conventions. Otherwise use these defaults.

## General
- `snake_case`, lowercase, ASCII only; no reserved words (`user`, `order`, `group` → `users`, `orders`, `groups`); no abbreviations unless universal (`id`, `url`, `ip`).
- Name things for what they are in the business domain, matching the BA glossary.

## Objects
| Object | Convention | Example |
|---|---|---|
| Table | Plural noun | `orders`, `order_lines` |
| Join table | Both entities, alphabetical, plural | `products_tags` (or the domain name if there is one: `memberships`) |
| Column | Singular noun | `status`, `total_cents` |
| Primary key | `id` | `id` |
| Foreign key column | `<singular_referenced_table>_id` | `customer_id` |
| Boolean | `is_`/`has_`/`can_` prefix | `is_active`, `has_paid` |
| Timestamp | `<event>_at` | `created_at`, `shipped_at`, `deleted_at` |
| Date | `<event>_on` | `birth_on`, `due_on` |
| Money | `<name>_cents` (+ `currency`), or `<name>_amount` for numeric | `total_cents` |
| Counts | `<thing>_count` | `item_count` |
| JSON | `<name>_data` / `<name>_payload` | `provider_payload` |

## Constraints and indexes
| Object | Pattern | Example |
|---|---|---|
| Primary key | `pk_<table>` | `pk_orders` |
| Foreign key | `fk_<table>__<referenced_table>` (add the column when it's ambiguous) | `fk_orders__customers` |
| Unique | `uq_<table>__<col>[_<col>]` | `uq_users__email` |
| Check | `ck_<table>__<rule>` | `ck_orders__total_non_negative` |
| Index | `ix_<table>__<col>[_<col>]` | `ix_orders__customer_id_created_at` |
| Partial index | `ix_<table>__<cols>__<condition>` | `ix_users__email__active` |
| Trigger | `tg_<table>__<purpose>` | `tg_orders__set_updated_at` |
| View / materialized view | `v_<name>` / `mv_<name>` | `mv_daily_sales` |
| Sequence (if explicit) | `<table>_<col>_seq` | — |

## Migrations
- File name: `<timestamp UTC YYYYMMDDHHMMSS>_<verb>_<object>.<ext>`, e.g. `20260301120000_add_status_to_orders.sql`. Use the tool's generator format if it enforces one.
- One logical change per migration. The description states the intent (`add`, `create`, `backfill`, `drop`, `rename_via_expand`).

## Environment and schema
- One schema per application by default (`public`, or the app name). Separate schemas for `audit` or `reporting` when access differs.
- Database roles: `<app>_migrator` (DDL), `<app>_app` (DML only), `<app>_readonly` (reporting). The application never connects as the owner or superuser.
