"""Stage 1 — a tiny 'hello world' Lambda, deployed by hand via the AWS Console.

A Lambda 'handler' is just a function AWS calls when the function is invoked.
It receives two arguments:
  - event:   the input data (a Python dict). Who/what invoked us and with what.
  - context: runtime info from AWS (request id, time remaining, etc.).

Whatever we return becomes the function's response.
Anything we print() shows up in CloudWatch Logs.
"""

import json


def lambda_handler(event, context):
    # This line will appear in CloudWatch Logs — proof our code ran.
    print("Hello from Lambda! Received event:", json.dumps(event))

    name = event.get("name", "world")

    return {
        "statusCode": 200,
        "body": json.dumps({"message": f"Hello, {name}!"}),
    }
