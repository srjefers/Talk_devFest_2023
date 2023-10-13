with final as (
    select *
    from {{ source('silver_demo', 'tbl_telco_cust_churn') }}
)
select * from final