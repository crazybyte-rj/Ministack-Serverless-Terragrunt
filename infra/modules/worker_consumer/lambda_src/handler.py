import json
import logging
import os
from datetime import datetime, timezone

import boto3

logger = logging.getLogger()
logger.setLevel(logging.INFO)


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
    return dynamodb.Table(os.environ["DYNAMODB_TABLE_NAME"])


def lambda_handler(event, context):
    table = _table()
    records = event.get("Records", [])
    batch_item_failures = []

    _structured_log("INFO", "Worker processing batch", record_count=len(records))

    processed = 0
    failed = 0

    for record in records:
        try:
            message_id = record.get("messageId", "unknown")
            raw_body = record.get("body", "{}")
            try:
                payload = json.loads(raw_body)
            except json.JSONDecodeError:
                payload = {"raw": raw_body}

            event_id = payload.get("id", record.get("messageId", "unknown"))
            event_type = payload.get("type", "unknown")

            _structured_log(
                "INFO",
                "Processing event",
                event_id=event_id,
                event_type=event_type
            )

            if payload.get("force_fail") is True:
                raise RuntimeError("forced failure for DLQ validation")

            table.put_item(
                Item={
                    "pk": f"EVENT#{event_id}",
                    "sk": "v1",
                    "type": event_type,
                    "payload": json.dumps(payload),
                    "status": "COMPLETED",
                    "ingested_at": payload.get("created_at", datetime.now(timezone.utc).isoformat()),
                    "processed_at": datetime.now(timezone.utc).isoformat(),
                }
            )

            _structured_log(
                "INFO",
                "Event persisted",
                event_id=event_id,
                table_name=os.environ["DYNAMODB_TABLE_NAME"]
            )

            processed += 1

        except Exception as e:
            failed += 1
            batch_item_failures.append({"itemIdentifier": message_id})
            _structured_log(
                "ERROR",
                "Failed to process record",
                error=str(e),
                record_id=message_id
            )

    _structured_log(
        "INFO",
        "Worker batch complete",
        processed=processed,
        failed=failed
    )

    return {
        "statusCode": 200,
        "processed": processed,
        "failed": failed,
        "batchItemFailures": batch_item_failures,
    }
