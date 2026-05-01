with source as (
    select * from {{ ref('raw_customers') }}
),

renamed as (
    select
        id          as customer_id,
        first_name,
        last_name,
        first_name || ' ' || last_name as full_name,
        email,
        country,
        created_at  as customer_created_at
    from source
)

select * from renamed
