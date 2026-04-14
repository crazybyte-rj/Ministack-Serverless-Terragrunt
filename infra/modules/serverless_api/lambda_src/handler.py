import json


def lambda_handler(event, context):
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(
            {
                "message": "Hello from ministack + terragrunt",
                "path": event.get("rawPath", ""),
                "requestId": event.get("requestContext", {}).get("requestId", ""),
            }
        ),
    }
