with customers as (
    select * from {{ ref('stg_customers') }}
),

orders as (
    select
        customer_id,
        count(*)                            as total_orders,
        count(case when is_completed then 1 end) as completed_orders,
        sum(order_amount)                   as lifetime_value,
        min(order_date)                     as first_order_date,
        max(order_date)                     as most_recent_order_date
    from {{ ref('stg_orders') }}
    group by customer_id
),

final as (
    select
        c.customer_id,
        c.first_name,
        c.last_name,
        c.full_name,
        c.email,
        c.country,
        c.customer_created_at,
        coalesce(o.total_orders, 0)         as total_orders,
        coalesce(o.completed_orders, 0)     as completed_orders,
        coalesce(o.lifetime_value, 0)       as lifetime_value,
        o.first_order_date,
        o.most_recent_order_date,
        case
            when o.total_orders > 0 then true
            else false
        end                                 as is_active
    from customers c
    left join orders o using (customer_id)
)

select * from final
