import os
import urllib.parse
from datetime import datetime

import boto3
from botocore.exceptions import ClientError

dynamodb = boto3.client('dynamodb')
output_dynamodb_table = os.getenv("OUTPUT_DYNAMODB_TABLE")

def lambda_handler(event, context):
    obj = event['Records'][0]['s3']['object']

    key = urllib.parse.unquote_plus(obj['key'], encoding='utf-8')

    fields = key.rsplit("/", 1)
    if len(fields) == 1:
        path = ""
        file_name = fields[0]
    else:
        path, file_name = fields

    item = {
        "file_path": {"S": path},
        "file_name": {"S": file_name},
        "metadata": {
            "M": {
                "size": {"N": str(obj['size'])},
                "date": {"S": datetime.today().strftime("%Y-%m-%d")},
                "etag": {"S": obj['eTag']}
            }
        }
    }

    try:
        dynamodb.put_item(TableName=output_dynamodb_table,
                          Item=item)

    except ClientError as err:
        print(err)
        raise err
