"""
Shared Lambda handler – responds to API Gateway proxy events.
Reads/writes DynamoDB and S3.  Accessible from both dev and test VPCs
through the private API Gateway endpoint.
"""

import json
import os
import boto3
from botocore.exceptions import ClientError

DYNAMODB_TABLE = os.environ.get("DYNAMODB_TABLE", "")
S3_BUCKET = os.environ.get("S3_BUCKET", "")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "shared")

dynamodb = boto3.resource("dynamodb")
s3 = boto3.client("s3")


def _ok(body):
    return {"statusCode": 200, "headers": {"Content-Type": "application/json"}, "body": json.dumps(body)}


def _err(status, msg):
    return {"statusCode": status, "headers": {"Content-Type": "application/json"}, "body": json.dumps({"error": msg})}


def lambda_handler(event, context):
    method = event.get("httpMethod", "GET")
    path = event.get("path", "/")
    qs = event.get("queryStringParameters") or {}

    # ── Health check ─────────────────────────────────────────────────────────
    if path == "/health":
        return _ok({"status": "healthy", "environment": ENVIRONMENT})

    # ── DynamoDB: GET /item?pk=<pk>&sk=<sk> ──────────────────────────────────
    if method == "GET" and path == "/item":
        pk = qs.get("pk")
        sk = qs.get("sk")
        if not pk:
            return _err(400, "pk query param required")
        table = dynamodb.Table(DYNAMODB_TABLE)
        key = {"pk": pk}
        if sk:
            key["sk"] = sk
        try:
            resp = table.get_item(Key=key)
            item = resp.get("Item")
            if not item:
                return _err(404, "item not found")
            return _ok(item)
        except ClientError as exc:
            return _err(500, str(exc))

    # ── DynamoDB: POST /item (body: JSON object with pk + sk + payload) ───────
    if method == "POST" and path == "/item":
        try:
            body = json.loads(event.get("body") or "{}")
        except json.JSONDecodeError:
            return _err(400, "invalid JSON body")
        if "pk" not in body:
            return _err(400, "body must contain pk")
        table = dynamodb.Table(DYNAMODB_TABLE)
        try:
            table.put_item(Item=body)
            return _ok({"message": "item stored", "pk": body["pk"]})
        except ClientError as exc:
            return _err(500, str(exc))

    # ── S3: GET /object?key=<key> ─────────────────────────────────────────────
    if method == "GET" and path == "/object":
        key = qs.get("key")
        if not key:
            return _err(400, "key query param required")
        try:
            resp = s3.get_object(Bucket=S3_BUCKET, Key=key)
            content = resp["Body"].read().decode("utf-8")
            return _ok({"key": key, "content": content})
        except ClientError as exc:
            code = exc.response["Error"]["Code"]
            if code in ("NoSuchKey", "404"):
                return _err(404, "object not found")
            return _err(500, str(exc))

    # ── S3: PUT /object?key=<key> (body: raw string) ──────────────────────────
    if method == "PUT" and path == "/object":
        key = qs.get("key")
        if not key:
            return _err(400, "key query param required")
        body = event.get("body") or ""
        try:
            s3.put_object(Bucket=S3_BUCKET, Key=key, Body=body.encode("utf-8"))
            return _ok({"message": "object stored", "key": key})
        except ClientError as exc:
            return _err(500, str(exc))

    return _err(404, f"no route for {method} {path}")
