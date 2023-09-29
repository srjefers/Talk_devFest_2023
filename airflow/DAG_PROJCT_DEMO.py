from airflow.models import DAG
from airflow.sensors.s3_prefix_sensor import S3PrefixSensor
from datetime import datetime, timedelta
from airflow.contrib.operators.ecs_operator import ECSOperator
from airflow.models import Variable
import pendulum
import pytz
import copy

correo=Variable.get('correo', deserialize_json=True)

awsRegionName       = 'us-east-1'
awsCluster          = 'aws-ecs-demo'
awsTaskDefinition   = 'aws-task-demo-a'
awsNetworkSubnet    = 'subnet-0883c91cd73edfbfc'    # ???
awsContainerName    = 'aws-repo-dbt-demo'
awsSG               = 'sg-0349ad47ca10e6e74'
awsLogGroup         = '/ecs/aws-task-demo-a'

default_args = {
    'owner': 'DEV_AWS',
    'depends_on_past': False,
    # 'email': correo['DEV_AWS_MAIL'],
    # 'email_on_failure': True,
    # 'email_on_retry': True,
    'retries': 1,
    'retry_delay': timedelta(minutes=1),
    'is_paused_upon_creation': False,
}

dag = DAG(
    dag_id='PRYCT_DEMO',
    start_date=datetime(2022,6,25,0,tzinfo=pendulum.timezone('America/Guatemala')),
    schedule_interval='0 7 * * *',
    max_active_runs=1,
    default_args=default_args,
    catchup=True,
    tags=['NA']
)

ecs_operator_args_template = {
    'aws_conn_id' : 'aws_default',
    'region_name' : awsRegionName,
    'launch_type' : 'FARGATE',
    'cluster' : awsCluster,
    'task_definition' : awsTaskDefinition,
    'network_configuration' : {
        'awsvpcConfiguration' : {
            'assignPublicIp' : 'ENABLED',
            'subnets' : [ awsNetworkSubnet ],
            'securityGroups' : [
                awsSG
            ],
        }
    },
    'awslogs_group' : awsLogGroup,
    'awslogs_stream_prefix' : 'ecs/' + awsContainerName,
}

ecs_operator_args = copy.deepcopy(ecs_operator_args_template)

PROCESS_ST_TRIPS_ATHENA = ECSOperator(
    task_id = 'PROCESS_ST_TRIPS',
    overrides = {
        'containerOverrides' : [
            {
                'name': awsContainerName,
                'command':["run"]
            },
        ],
    },
    dag = dag,
    **ecs_operator_args
)

PROCESS_ST_TRIPS_ATHENA