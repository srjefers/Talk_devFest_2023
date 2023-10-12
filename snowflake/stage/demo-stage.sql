------------------------------------------
-- query --> 001
-- create a new database
create database test_connection;
use database test_connection;
create schema test_schema;


-- create a new user and role
set business_user = 'SRJEFERS';
set username = '"SRJEFERS"';

use role SECURITYADMIN;
use warehouse COMPUTE_WH;
set reader_role = $business_user || '_READER';

set role_comment = ' reader role for user ' || $username;
create role if not exists identifier($reader_role) comment = $role_comment;

-- set reader_role = 'TEST_CONNECTION_USAGE';
-- set roleComment = 'TEST_CONNECTION_USAGE usage non-prod role';
-- set ad_hoc_warehouse = 'COMPUTE_WH';
-- create role identifier($reader_role) comment = $roleComment;

-- grant some access to the role
grant role TEST_CONNECTION_USAGE to role "SRJEFERS_READER";
grant role SRJEFERS_READER to user "SRJEFERS";
-- grant usage on database test_connection to identifier($reader_role);
-- grant usage on warehouse identifier($ad_hoc_warehouse) to role identifier($reader_role);
grant all on warehouse COMPUTE_WH to role TEST_CONNECTION_USAGE;
grant usage on database test_connection to role TEST_CONNECTION_USAGE;
grant create schema on database test_connection to role TEST_CONNECTION_USAGE; 
grant usage on schema test_connection.test_schema to role TEST_CONNECTION_USAGE;
grant create table on schema test_connection.test_schema to role TEST_CONNECTION_USAGE;
grant create view on schema test_connection.test_schema to role TEST_CONNECTION_USAGE;
grant usage on future schemas in database test_connection to role TEST_CONNECTION_USAGE;
grant monitor on future schemas in database test_connection to role TEST_CONNECTION_USAGE;
grant select on future tables in database test_connection to role TEST_CONNECTION_USAGE;
grant select on future views in database test_connection to role TEST_CONNECTION_USAGE;
grant usage on all schemas in database test_connection to role TEST_CONNECTION_USAGE;
grant monitor on all schemas in database test_connection to role TEST_CONNECTION_USAGE;
grant select on all tables in database test_connection to role TEST_CONNECTION_USAGE;
grant select on all views in database test_connection to role TEST_CONNECTION_USAGE;
grant create STAGE on schema public to role SRJEFERS_READER;
grant create file FORMAT on schema public to role SRJEFERS_READER;
grant create pipe on schema public to role SRJEFERS_READER;

------------------------------------------
-- QUERY 003 INTEGRATION 
use role ACCOUNTADMIN;
select system$GET_SNOWFLAKE_PLATFORM_INFO();

create STORAGE INTEGRATION s3_int
  type = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  enabled = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::466854116461:role/demo-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://bucket-demo-dbt/raw-data/');

desc INTEGRATION s3_int;

-- grant usage on the integration to the role
grant usage on INTEGRATION s3_int to role SRJEFERS_READER;

------------------------------------------
-- >> lets create the first stage based on our integration <<
use schema TEST_CONNECTION.public;
create stage my_s3_stage3
  STORAGE_INTEGRATION = s3_int
  url = 's3://bucket-demo-dbt/raw-data/'
  file_format = (type = 'CSV');

-- test stage table
/*
select    
    metadata$filename, 
    metadata$file_row_number,
    t.$1, 
    t.$2    
from TEST_CONNECTION.PUBLIC.MY_S3_STAGE3;
*/

-- list all the files on the stage/bucket-path
LIST @MY_S3_STAGE3;

-- we can also define a file format on our schema
create or replace file format myformat_comma type = 'csv' FIELD_DELIMITER = ',';

-- QUERY 005
create or replace STAGE my_s3_stage0
  STORAGE_INTEGRATION = s3_int
  url = 's3://bucket-demo-dbt/raw-data/'
  directory = (
    enable = true
    AUTO_REFRESH = true
  )
  file_format = (
      TYPE = 'CSV' 
      SKIP_HEADER = 1
      SKIP_BLANK_LINES = TRUE
    );

/*
    >>> NOTE <<<
    SNOWFLAKE doesn't allows to query by columns or to set names to the stages columns
    -- We can also execute a bulk insert over to another view/table
*/

-------------------------------------------------
-- lest create a new table to bulk our data on it
create table TEST_CONNECTION.TEST_SCHEMA.SOURCE_DATA (
    id varchar(255),
    email varchar(255)
);

-- copy
-- we can copy/insert bulk the data from stages into tables/views 
copy into TEST_CONNECTION.TEST_SCHEMA.SOURCE_DATA
from @MY_S3_STAGE0
ON_ERROR = 'CONTINUE';


-- pipe
-- this is an automated way to execute them from external resources
use database test_connection;
create or replace pipe snowpipe_daily_demo_aws 
        AUTO_INGEST=TRUE 
    as
    copy into TEST_CONNECTION.TEST_SCHEMA.SOURCE_DATA
    from @MY_S3_STAGE0
    ON_ERROR = 'CONTINUE';

/*
    --> snowflake 
    * STAGE         my_s3_stage0
    * PIPE          snowpipe_daily_demo
    * INTEGRATION   s3_int
    * ROLE          SRJEFERS_READER
    * SOURCE        TEST_CONNECTION.TEST_SCHEMA.SOURCE_DATA
    * DDATABASE     TEST_CONNECTION

    >>> NOTE <<<
    show pipes;
    
    -- by showing the pipes we can check how they works and also which is the sns/sqs values defines
    -- sqs is defined by default from snowflake
    -- sns is defined by the user

    select SYSTEM$PIPE_STATUS( 'snowpipe_daily_demo_aws' );

    -- we can also review the status and some logs from the execution of our sqs

    >>> DOCS <<<
    * https://docs.snowflake.com/en/sql-reference/sql/create-stage#external-stages
    * https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3
    * https://docs.snowflake.com/en/user-guide/data-load-snowpipe-auto-s3#option-2-configuring-amazon-sns-to-automate-snowpipe-using-sqs-notifications
    * https://docs.snowflake.com/en/user-guide/data-load-snowpipe-ts
*/