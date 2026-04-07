{{
  config(
    materialized = 'table',
    schema       = 'franchise_agent_marts'
  )
}}

with orders as (
    select * from {{ ref('stg_order_header') }}
),

trucks as (
    select
        truck_id,
        franchise_id,
        primary_city,
        country,
        menu_type_id,
        truck_opening_date
    from {{ source('raw_pos', 'truck') }}
),

franchise as (
    select * from {{ ref('stg_franchise') }}
),

menu as (
    select
        menu_type_id,
        truck_brand_name
    from {{ source('raw_pos', 'menu') }}
    qualify row_number() over (partition by menu_type_id order by menu_item_id) = 1
),

joined as (
    select
        o.order_id,
        o.order_ts,
        o.order_month,
        o.order_channel,
        o.order_amount,
        o.order_total,
        t.truck_id,
        t.franchise_id,
        t.primary_city,
        t.country,
        t.truck_opening_date,
        f.franchise_owner_name,
        f.franchise_city,
        f.franchise_country,
        m.truck_brand_name
    from orders          o
    join trucks          t  on o.truck_id    = t.truck_id
    join franchise       f  on t.franchise_id = f.franchise_id
    left join menu       m  on t.menu_type_id = m.menu_type_id
),

aggregated as (
    select
        franchise_id,
        franchise_owner_name,
        franchise_city,
        franchise_country,
        truck_brand_name,
        primary_city         as truck_city,
        order_month,
        count(order_id)      as total_orders,
        sum(order_total)     as total_revenue,
        avg(order_total)     as avg_order_value,
        count(distinct truck_id) as active_trucks
    from joined
    group by 1, 2, 3, 4, 5, 6, 7
)

select * from aggregated