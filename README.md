# Talk Dev Fest 2023

## What I did
Today I started the Demo that is going to be used on the presentation for the Dev Fest 2023, the title of this presentation is going to be "Lets talk about data and cloud", for this presentation I am going to prepare a Demo with the next stack 
* DBT
* Docker
* Airflow
* AWS S3
* AWS EC2
* Snowflake
The propouse of this talk is to show how dbt implements an easy way to configure, build and create a DataWarehouse on Cloud. I was thinking about using Redshift also but it depends.

Today I had the chance to configure and run with success dbt-core on my machine, also configure an Snowflake account and database.
Also I had the chance to create a connection between dbt-core with snowflake, and had a chance to execute a `dbt run` to build some models on Snowflake. To test the connection I execute `dbt debug`

## Questions 
* How to load this project on Docker?
* How to load this Docker into AWS?
* How to create a security group and allow aws EC2 to run and connecto to Snowflake?
* How to create an AWS Lambda that detect when a file is deposited on the AWS S3, and run the EC2 or instead of using EC2, execute Airflow to execute the pipeline?
* How to configure AWS Airflow to Run EC2 on demand?

## Next steps
Start a research to find how to conteinerize the dbt solution and upload to AWS EC2, also how to allow this EC2 fargate to run and reach Snowflake to build test models.

Also create a Dag and be able to run the conteinerized solution.

## Some links with information
* https://docs.aws.amazon.com/mwaa/latest/userguide/samples-lambda.html
* https://docs.getdbt.com/faqs/Warehouse/connecting-to-two-dbs-not-allowed
* https://docs.getdbt.com/docs/core/pip-install#using-virtual-environments
* https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-authentication
* https://stackoverflow.com/a/77182992/7102575