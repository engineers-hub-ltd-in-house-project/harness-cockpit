import json
import os
import uuid
from datetime import datetime, timezone

import boto3

logs_client = boto3.client("logs")
LOG_GROUP = os.environ["LOG_GROUP"]

REQUIRED_FIELDS = ("event_type", "session_id", "tool_name")


def handler(event, context):
    try:
        body = json.loads(event.get("body", "{}"))
    except (json.JSONDecodeError, TypeError):
        return {
            "statusCode": 400,
            "body": json.dumps({"error": "Invalid JSON body"}),
        }

    missing = [f for f in REQUIRED_FIELDS if not body.get(f)]
    if missing:
        return {
            "statusCode": 400,
            "body": json.dumps({"error": f"Missing required fields: {', '.join(missing)}"}),
        }

    now = datetime.now(timezone.utc)
    body["event_id"] = f"evt_{uuid.uuid4()}"
    body["received_at"] = now.isoformat()

    session_id = body.get("session_id", "unknown")
    log_stream = f"{session_id}/{now.strftime('%Y-%m-%d')}"
    timestamp_ms = int(now.timestamp() * 1000)
    message = json.dumps(body, ensure_ascii=False)

    log_event = {"timestamp": timestamp_ms, "message": message}

    try:
        _put_log_events(log_stream, log_event)
    except logs_client.exceptions.ResourceNotFoundException:
        _create_log_stream(log_stream)
        _put_log_events(log_stream, log_event)

    return {
        "statusCode": 200,
        "body": json.dumps({"event_id": body["event_id"]}),
    }


def _put_log_events(log_stream, log_event):
    logs_client.put_log_events(
        logGroupName=LOG_GROUP,
        logStreamName=log_stream,
        logEvents=[log_event],
    )


def _create_log_stream(log_stream):
    try:
        logs_client.create_log_stream(
            logGroupName=LOG_GROUP,
            logStreamName=log_stream,
        )
    except logs_client.exceptions.ResourceAlreadyExistsException:
        pass
