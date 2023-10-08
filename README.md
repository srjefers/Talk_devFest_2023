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
### How to load this project on Docker?
Fist things first, we need to define a docker file for this kind of task, we can find an example of a dockerFile an the official documentation. So we can base our docker file on it and be able to conteinerize our dbt solution. Don't forget to copy the profiles.yml and hide all the sensitive information in the envfile.
https://github.com/dbt-labs/dbt-core/blob/main/docker/Dockerfile

`sudo docker run -i -t dbt:latest run`

### How to load this Docker into AWS?
Firts, I created a new aws account. Lest create the next list of components: 
* awsCluster        -> aws-ecs-demo
* awsTaskDefinition -> aws-task-demo-a:1 
* awsVPC            -> 
* awsSG             -> aws-sg-demo-a
* awsEcr            -> 466854116461.dkr.ecr.us-east-1.amazonaws.com/aws-repo-dbt-demo

We are going to create a `run task` to execute this task on the way, we already set all the enviroment variables on the creation of the task. It would be better if we find a way to set an aws kms for those credentials

### How to create a security group and allow aws EC2 to run and connecto to Snowflake?
I has been able to execute this ECR and able to reach Snowflake, I had to set a SG and somo vpc changes.
aws-sg-demo-a

### How to configure AWS Airflow to Run EC2 on demand?
I am dealing with this issue now, I am trying to use AWS MWAA to set an env of airflow easily but some configurations are going wrong on the side
of the network. So I am eveluating creating a simple EC2 to set airflow there and then I guess that I will need to deal on HOW to execute thos run task from ec2 or intead we can use another alternative from the aws services such like aws step functions.

Well, at the end I decided to go for StepFunctions, it would be much easier to work with them than defining an airflow env.

```json
{
  "StartAt": "Run Fargate Task",
  "TimeoutSeconds": 3600,
  "States": {
    "Run Fargate Task": {
      "Type": "Task",
      "Resource": "arn:aws:states:::ecs:runTask.sync",
      "Parameters": {
        "LaunchType": "FARGATE",
        "Cluster": "arn:aws:ecs:us-east-1:466854116461:cluster/aws-ecs-demo",
        "TaskDefinition": "arn:aws:ecs:us-east-1:466854116461:task-definition/aws-task-demo-a:1",
        "NetworkConfiguration": {
          "AwsvpcConfiguration": {
            "Subnets": [
              "subnet-0883c91cd73edfbfc",
              "subnet-05a378b1515ec40aa",
              "subnet-00c9ffaa0c22ec432",
              "subnet-07dd11371247c17f7"
            ],
            "AssignPublicIp": "ENABLED"
          }
        }
      },
      "End": true
    }
  }
}
```

Its funny, maybe I just had not enough sleep but I was dealing with an issue related to roles, but the role parameter is optional, I was dealing with it for a while but now is fixed and the execution of this StateMachine is working.

### How to create an AWS Lambda that detect when a file is deposited on the AWS S3, and run the EC2 or instead of using EC2, execute Airflow to execute the pipeline?

There are some templetes that makes the task easy to deploy a lambda function, also in the aws docs you can find how to deploy a lambda function that triggers an aws step functions task. You need also to grant some access to the role that you created to the aws lambda.

```python
import json
import urllib.parse
import boto3

print('Loading function')

s3 = boto3.client('s3')
sf = boto3.client('stepfunctions', region_name = 'us-east-1')

def lambda_handler(event, context):

    try:
        print("SF execution status starting ----> ")
        input_dict = {'key': 'value'}
        response_sf = sf.start_execution(
            stateMachineArn = 'arn:aws:states:us-east-1:466854116461:stateMachine:aws-stepfunc-demo-fargate1',
            input = json.dumps(input_dict)
        )
    
        print("SF execution status --->>>>" + str(response_sf))
        
        return json.dumps(response_sf, default=str)
    except Exception as e:
        print(e)
        raise e
```

### How to read s3 bucket and files from dbt and load them into snowflake?
As part of my research to find a way to have the raw data that is being deposited on the aws s3 bucket, I finded that snowflake provides a way to read the data on aws by creating `stage external` tables, that allows snowflake to reach the raw data from aws and get it into snowflake.

```sql
CREATE STORAGE INTEGRATION s3_int
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::466854116461:role/demo-snowflake-role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://bucket-demo-dbt/raw-data/');

DESC INTEGRATION s3_int;

GRANT CREATE STAGE ON SCHEMA public TO ROLE SRJEFERS_READER;
GRANT CREATE FILE FORMAT ON SCHEMA public TO ROLE SRJEFERS_READER;

GRANT USAGE ON INTEGRATION s3_int TO ROLE SRJEFERS_READER;

USE SCHEMA TEST_CONNECTION.public;

CREATE STAGE my_s3_stage3
  STORAGE_INTEGRATION = s3_int
  URL = 's3://bucket-demo-dbt/raw-data/'
  FILE_FORMAT = (TYPE = 'CSV');

LIST @MY_S3_STAGE3;

CREATE TABLE test_schema.test AS 
SELECT 
   -- metadata$filename, 
   -- metadata$file_row_number, 
   t.$1, 
   t.$2
FROM @MY_S3_STAGE3 t;
```


As an additional, I am going to add an extra step that is related to the dbt package called `dbt-labs/dbt_external_tables` to be able to execute and refresh all the external stages that has been created. 


> Posted a quetion on StackOverflow -> https://stackoverflow.com/questions/77248767/dbt-external-tables-not-being-executed

## Next steps
Add external stages to the dbt project, and load the data that is in aws s3 to snowflake. Being able to execute a query to see the data on Snowflake. Transform that data and build a model with the data.

## Some links with information
* https://docs.aws.amazon.com/mwaa/latest/userguide/samples-lambda.html
* https://docs.getdbt.com/faqs/Warehouse/connecting-to-two-dbs-not-allowed
* https://docs.getdbt.com/docs/core/pip-install#using-virtual-environments
* https://docs.snowflake.com/en/user-guide/key-pair-auth#configuring-key-pair-authentication
* https://stackoverflow.com/a/77182992/7102575
* https://github.com/dbt-labs/dbt-snowflake/pkgs/container/dbt-snowflake
* https://github.com/dbt-labs/dbt-core/blob/main/docker/Dockerfile
* https://repost.aws/knowledge-center/mwaa-stuck-creating-state
* https://docs.aws.amazon.com/mwaa/latest/userguide/vpc-vpe-create-access.html
* https://docs.aws.amazon.com/step-functions/latest/dg/concepts-invoke-sfn.html
* http://mamykin.com/posts/fast-data-load-snowflake-dbt/
* https://medium.com/@dipan.saha/migrating-historical-and-real-time-data-from-aws-s3-to-snowflake-402ccfd4c423
* https://medium.com/slateco-blog/doing-more-with-less-usingdbt-to-load-data-from-aws-s3-to-snowflake-via-external-tables-a699d290b93f
* https://docs.snowflake.com/en/user-guide/data-load-s3-allow
* https://docs.snowflake.com/en/user-guide/data-load-s3-config-storage-integration
* https://docs.snowflake.com/en/user-guide/querying-stage
* https://hub.getdbt.com/dbt-labs/dbt_external_tables/latest/