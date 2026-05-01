with source as (
    select * from {{ ref('raw_orders') }}
),

renamed as (
    select
        id          as order_id,
        customer_id,
        order_date,
        status      as order_status,
        amount      as order_amount,
        case
            when status in ('completed') then true
            else false
        end         as is_completed
    from source
)

select * from renamed
