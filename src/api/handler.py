"""API Lambda — reads ISS data from DynamoDB and returns it as JSON.

Runs synchronously: a visitor's browser is waiting for the answer.

Two endpoints:
  GET /latest          -> the single most recent ISS reading
  GET /history?limit=N -> the last N readings (default 10, max 100)
"""

import json
import os
from decimal import Decimal

import boto3
from boto3.dynamodb.conditions import Key

TABLE_NAME = os.environ["TABLE_NAME"]
dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def _to_jsonable(value):
    """DynamoDB gives numbers back as Decimal, which JSON can't handle.
    Convert whole numbers to int and the rest to float."""
    if isinstance(value, Decimal):
        return int(value) if value % 1 == 0 else float(value)
    raise TypeError(f"not JSON serializable: {type(value)}")


def _respond(status, body):
    return {
        "statusCode": status,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body, default=_to_jsonable),
    }


def _latest_readings(limit):
    """Query the 'iss' partition, newest first."""
    result = table.query(
        KeyConditionExpression=Key("series_id").eq("iss"),
        ScanIndexForward=False,  # False = descending = newest first
        Limit=limit,
    )
    return result.get("Items", [])


def lambda_handler(event, context):
    path = event.get("rawPath", "/")
    params = event.get("queryStringParameters") or {}

    if path == "/latest":
        items = _latest_readings(1)
        return _respond(200, items[0] if items else {})

    if path == "/history":
        try:
            limit = int(params.get("limit", "10"))
        except (TypeError, ValueError):
            limit = 10
        limit = max(1, min(limit, 100))  # keep it sane
        return _respond(200, _latest_readings(limit))

    return _respond(404, {"error": "not found", "path": path})
