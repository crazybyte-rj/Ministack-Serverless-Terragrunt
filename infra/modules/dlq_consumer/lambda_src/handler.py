import json
import logging
import os
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)

DLQ_TABLE_NAME = os.environ["DLQ_TABLE_NAME"]
SNS_ALERT_TOPIC = os.environ["SNS_ALERT_TOPIC"]


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


def _dynamodb_table():
    endpoint = os.environ.get("AWS_ENDPOINT_URL")
    kwargs = {
        "region_name": os.environ.get("AWS_REGION", "us-east-1"),
        "aws_access_key_id": os.environ.get("AWS_ACCESS_KEY_ID", "test"),
        "aws_secret_access_key": os.environ.get("AWS_SECRET_ACCESS_KEY", "test"),
    }
    if endpoint:
        kwargs["endpoint_url"] = endpoint
    dynamodb = boto3.resource("dynamodb", **kwargs)
    return dynamodb.Table(DLQ_TABLE_NAME)


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


def lambda_handler(event, context):
    records = event.get("Records", [])
    _structured_log(
        "INFO",
        "DLQ consumer triggered",
        record_count=len(records)
    )

    table = _dynamodb_table()
    sns = _sns_client()
    processed = 0
    failed = 0

    for record in records:
        try:
            raw_body = record.get("body", "{}")
            payload = json.loads(raw_body)
            event_id = payload.get("id", record.get("messageId", "unknown"))
            reason = payload.get("reason", "unknown error")

            _structured_log(
                "WARNING",
                "DLQ message received",
                event_id=event_id,
                reason=reason
            )

            # Log failed event to DynamoDB
            table.put_item(
                Item={
                    "pk": f"DLQ#{event_id}",
                    "sk": datetime.now(timezone.utc).isoformat(),
                    "event_id": event_id,
                    "reason": reason,
                    "payload": json.dumps(payload),
                    "recorded_at": datetime.now(timezone.utc).isoformat(),
                }
            )

            # Send alert via SNS
            alert_message = f"""
DLQ Alert - Event Processing Failed

Event ID: {event_id}
Reason: {reason}
Timestamp: {datetime.now(timezone.utc).isoformat()}
Payload: {json.dumps(payload, indent=2)}
"""
            sns.publish(
                TopicArn=SNS_ALERT_TOPIC,
                Subject=f"DLQ Alert - Event {event_id} Failed",
                Message=alert_message
            )

            processed += 1

        except Exception as e:
            failed += 1
            _structured_log(
                "ERROR",
                "Failed to process DLQ message",
                error=str(e),
                record=str(record)
            )

    _structured_log(
        "INFO",
        "DLQ consumer completed",
        processed=processed,
        failed=failed
    )

    return {"statusCode": 200, "processed": processed, "failed": failed}
