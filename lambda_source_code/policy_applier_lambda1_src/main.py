import boto3
import json
import logging
from sqlite_utils import Database
from botocore.exceptions import ClientError

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

db = Database("my_database.db")
iam_client = boto3.client('iam')

def validate_input(event):
    required_fields = ['policy_names', 'user_name']
    for field in required_fields:
        if field not in event:
            raise ValueError(f"Missing required field: {field}")
    
    if not isinstance(event['policy_names'], list):
        raise ValueError("policy_names must be a list")
    
    if not event['user_name']:
        raise ValueError("user_name cannot be empty")

def handler(event, context):
    try:
        logger.info(f"Received event: {json.dumps(event)}")
        validate_input(event)
        
        target_policies = event['policy_names']
        user_name = event['user_name']
        
        logger.info(f"Processing policies for user: {user_name}")
        
        results = []
        for policy in target_policies:
            try:
                statement = f"SELECT policy_name FROM policies WHERE policy_name=? AND public='True'"
                rows = list(db.query(statement, [policy]))
                
                if rows:
                    policy_arn = f"arn:aws:iam::aws:policy/{rows[0]['policy_name']}"
                    iam_client.attach_user_policy(
                        UserName=user_name,
                        PolicyArn=policy_arn
                    )
                    results.append({
                        "policy": policy,
                        "status": "success",
                        "message": f"Policy {policy} attached successfully"
                    })
                    logger.info(f"Successfully attached policy {policy} to user {user_name}")
                else:
                    results.append({
                        "policy": policy,
                        "status": "error",
                        "message": f"Policy {policy} is not approved"
                    })
                    logger.warning(f"Attempted to attach unauthorized policy: {policy}")
            
            except ClientError as e:
                error_message = e.response['Error']['Message']
                results.append({
                    "policy": policy,
                    "status": "error",
                    "message": error_message
                })
                logger.error(f"Error attaching policy {policy}: {error_message}")
        
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Policy attachment process completed",
                "results": results
            })
        }
        
    except Exception as e:
        logger.error(f"Error processing request: {str(e)}")
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e)
            })
        }


if __name__ == "__main__":
    payload = {
        "policy_names": [
            "AmazonSNSReadOnlyAccess",
            "AWSLambda_ReadOnlyAccess"
        ],
        "user_name": "cr-pentester-user"
    }
    print(handler(payload, 'uselessinfo'))
