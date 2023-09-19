import boto3

s3 = boto3.client("s3")

def handler(event, context):
    bucket_name = os.environ.get("S3_BUCKET_NAME")

    
    for record in event["Records"]:
        bucket = record["s3"]["bucket"]["name"]
        key = record["s3"]["object"]["key"]
        
        
        if key.endswith(".txt"):
            response = s3.get_object(Bucket=bucket, Key=key)
            object_contents = response["Body"].read().decode("utf-8")
            
            
            print(f"Object in bucket '{bucket}' with key '{key}' contains:")
            print(object_contents)