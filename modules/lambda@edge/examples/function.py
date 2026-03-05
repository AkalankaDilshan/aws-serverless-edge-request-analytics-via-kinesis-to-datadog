import boto3
import json

def lambda_hander(event, context):
    # get cloudfront response 
    print(event)