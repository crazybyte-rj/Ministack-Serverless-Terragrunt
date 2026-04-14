import json
import logging
import os
import uuid
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TOPIC_ARN = os.environ["SNS_TOPIC_ARN"]


def _structured_log(level, message, **extra):
    """Log in JSON format for CloudWatch"""
    log_entry = {
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "level": level,
        "message": message,
    }
    log_entry.update(extra)
    logger.log(
        getattr(logging, level),
        json.dumps(log_entry)
    )


def _sns_client():
    endpoint = os.environ.get("AWS_ENDPOINT_URL")
    kwargs = {
        "region_name": os.environ.get("AWS_REGION", "us-east-1"),
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }
    if endpoint:
        kwargs["endpoint_url"] = endpoint
    return boto3.client("sns", **kwargs)


def _response(status_code, body):
    return {
        "statusCode": status_code,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }


def _request_id(context):
    return getattr(context, "aws_request_id", None) or getattr(context, "request_id", "unknown")


def lambda_handler(event, context):
    request_id = _request_id(context)
    method = event.get("requestContext", {}).get("http", {}).get("method", "")
    path = event.get("rawPath", "")

    _structured_log("INFO", "Ingest request received", request_id=request_id, method=method, path=path)

    if method == "GET" and path == "/health":
        return _response(200, {"status": "ok"})

    body = event.get("body") or "{}"
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        _structured_log(
            "WARNING",
            "Invalid JSON payload",
            request_id=request_id,
            body=body
        )
        return _response(400, {"error": "invalid JSON payload"})

    event_id = payload.get("id", str(uuid.uuid4()))
    payload["id"] = event_id
    payload["status"] = "PENDING"
    payload["created_at"] = datetime.now(timezone.utc).isoformat()

    try:
        sns = _sns_client()
        sns.publish(
            TopicArn=TOPIC_ARN,
            Message=json.dumps(payload),
            MessageAttributes={
                "eventType": {
                    "DataType": "String",
                    "StringValue": payload.get("type", "unknown"),
                }
            },
        )

        _structured_log(
            "INFO",
            "Event published to SNS",
            request_id=request_id,
            event_id=event_id,
            event_type=payload.get("type")
        )

        return _response(202, {"message": "event accepted", "eventId": event_id})

    except Exception as e:
        _structured_log(
            "ERROR",
            "Failed to publish event",
            request_id=request_id,
            event_id=event_id,
            error=str(e)
        )
        return _response(500, {"error": "internal server error"})
