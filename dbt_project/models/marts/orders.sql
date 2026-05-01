with orders as (
    select * from {{ ref('stg_orders') }}
),

payments as (
    select
        order_id,
        sum(case when is_successful then payment_amount else 0 end) as total_paid,
        count(*) as payment_count,
        max(payment_method) as primary_payment_method
    from {{ ref('stg_payments') }}
    group by order_id
),

customers as (
    select * from {{ ref('stg_customers') }}
),

final as (
    select
        o.order_id,
        o.customer_id,
        c.full_name         as customer_name,
        c.country,
        o.order_date,
        o.order_status,
        o.order_amount,
        o.is_completed,
        coalesce(p.total_paid, 0)           as total_paid,
        coalesce(p.payment_count, 0)        as payment_count,
        coalesce(p.primary_payment_method, 'none') as payment_method
    from orders o
    left join customers c using (customer_id)
    left join payments p using (order_id)
)

select * from final
