with final as (
    select *
    from {{ source('silver_demo', 'my_s3_stage01') }}
)
select * from final