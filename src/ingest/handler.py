"""Ingest Lambda — fetches the ISS's current position and stores it in DynamoDB.

Triggered manually for now (and on a schedule in Stage 5). Runs asynchronously:
nobody is waiting for the response, it just needs to record a data point reliably.

Dependencies: none to package! We use:
  - urllib (Python standard library) for the HTTP call
  - boto3 (the AWS SDK, pre-installed in the Lambda runtime) for DynamoDB
"""

import json
import os
import urllib.request
from datetime import datetime, timezone
from decimal import Decimal

import boto3

# The ISS ("satellite 25544") position API — free, no key, HTTPS.
ISS_API_URL = "https://api.wheretheiss.at/v1/satellites/25544"

# Table name is injected by Terraform as an environment variable
# (so the code isn't hard-coded to one table).
TABLE_NAME = os.environ["TABLE_NAME"]

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(TABLE_NAME)


def fetch_iss_position():
    """Call the public API and return the parsed JSON dict."""
    with urllib.request.urlopen(ISS_API_URL, timeout=8) as resp:
        return json.loads(resp.read().decode())


def lambda_handler(event, context):
    data = fetch_iss_position()

    # ISO-8601 UTC timestamp — used as the DynamoDB sort key so rows
    # are naturally ordered by time within the "iss" partition.
    now = datetime.now(timezone.utc).isoformat()

    # NOTE: DynamoDB stores numbers as Decimal, not float. The standard
    # trick is Decimal(str(value)) to avoid float-precision errors.
    item = {
        "series_id": "iss",                                  # partition key
        "ts": now,                                           # sort key
        "latitude": Decimal(str(data["latitude"])),
        "longitude": Decimal(str(data["longitude"])),
        "altitude_km": Decimal(str(data["altitude"])),
        "velocity_kmh": Decimal(str(data["velocity"])),
        "source_timestamp": int(data["timestamp"]),
    }

    table.put_item(Item=item)
    print(f"Stored ISS position at {now}: "
          f"lat={item['latitude']} lon={item['longitude']}")

    return {
        "statusCode": 200,
        "body": json.dumps({"stored": now}),
    }
