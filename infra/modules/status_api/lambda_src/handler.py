import json
import logging
import os
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

TABLE_NAME = os.environ["DYNAMODB_TABLE_NAME"]


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


def _table():
    endpoint = os.environ.get("AWS_ENDPOINT_URL")
    kwargs = {
        "region_name": os.environ.get("AWS_REGION", "us-east-1"),
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }
    if endpoint:
        kwargs["endpoint_url"] = endpoint
    dynamodb = boto3.resource("dynamodb", **kwargs)
    return dynamodb.Table(TABLE_NAME)


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
    _structured_log("INFO", "Status query request", request_id=request_id)

    path = event.get("rawPath", "")
    
    if path == "/health":
        return _response(200, {"status": "ok"})

    # Extract event_id from path /events/{id}/status
    parts = path.split("/")
    if len(parts) != 4 or parts[1] != "events" or parts[3] != "status":
        _structured_log(
            "WARNING",
            "Invalid path",
            request_id=request_id,
            path=path
        )
        return _response(400, {"error": "invalid path"})

    event_id = parts[2]

    try:
        table = _table()
        response = table.get_item(Key={
            "pk": f"EVENT#{event_id}",
            "sk": "v1"
        })

        if "Item" not in response:
            _structured_log(
                "WARNING",
                "Event not found",
                request_id=request_id,
                event_id=event_id
            )
            return _response(404, {"error": "event not found"})

        item = response["Item"]
        status = item.get("status", "UNKNOWN")

        _structured_log(
            "INFO",
            "Event status retrieved",
            request_id=request_id,
            event_id=event_id,
            status=status
        )

        return _response(200, {
            "id": event_id,
            "status": status,
            "ingested_at": item.get("ingested_at"),
            "processed_at": item.get("processed_at"),
            "type": item.get("type"),
        })

    except Exception as e:
        _structured_log(
            "ERROR",
            "Failed to query status",
            request_id=request_id,
            event_id=event_id,
            error=str(e)
        )
        return _response(500, {"error": "internal server error"})
