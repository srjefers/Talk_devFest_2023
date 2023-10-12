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
        
        return 0
    except Exception as e:
        print(e)
        # print('Error getting object {} from bucket {}. Make sure they exist and your bucket is in the same region as this function.'.format(key, bucket))
        raise e
