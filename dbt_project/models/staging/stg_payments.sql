with source as (
    select * from {{ ref('raw_payments') }}
),

renamed as (
    select
        id              as payment_id,
        order_id,
        payment_method,
        amount          as payment_amount,
        payment_date,
        status          as payment_status,
        case
            when status = 'success' then true
            else false
        end             as is_successful
    from source
)

select * from renamed
