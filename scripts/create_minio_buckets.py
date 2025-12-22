import boto3
from botocore.exceptions import ClientError

# Configuration
endpoint = "http://192.168.4.31:9000"
access_key = "datalake"
secret_key = "iRB;g2&ChZ&XQEW!"
buckets_to_create = ["warehouse", "backup"]

print(f"Connecting to MinIO at {endpoint}...")

try:
    s3 = boto3.client('s3',
                      endpoint_url=endpoint,
                      aws_access_key_id=access_key,
                      aws_secret_access_key=secret_key)
    
    existing_buckets = [b['Name'] for b in s3.list_buckets()['Buckets']]
    
    for bucket in buckets_to_create:
        if bucket not in existing_buckets:
            print(f"Creating bucket: {bucket}")
            s3.create_bucket(Bucket=bucket)
            print(f"Bucket {bucket} created successfully.")
        else:
            print(f"Bucket {bucket} already exists.")

    print("\nFinal Bucket List:")
    response = s3.list_buckets()
    for bucket in response['Buckets']:
        print(f" - {bucket['Name']}")

except ClientError as e:
    print(f"Error connecting to MinIO: {e}")
except Exception as e:
    print(f"An unexpected error occurred: {e}")
