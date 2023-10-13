{{
  config(
    materialized = 'table',
  )
}}
with final as (
    select *
    from {{ source('external_demo', 'EXT_TELCO_CUST_CHURN') }}
)
select * from final