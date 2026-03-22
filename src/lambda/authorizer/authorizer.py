import os

import boto3

ssm_client = boto3.client("ssm")
TOKEN_PARAMETER_NAME = os.environ["TOKEN_PARAMETER_NAME"]

_cached_token = None


def _get_expected_token():
    global _cached_token
    if _cached_token is None:
        response = ssm_client.get_parameter(
            Name=TOKEN_PARAMETER_NAME, WithDecryption=True
        )
        _cached_token = response["Parameter"]["Value"]
    return _cached_token


def handler(event, context):
    token = event.get("headers", {}).get("authorization", "")
    if token.startswith("Bearer "):
        token = token[7:]

    expected = _get_expected_token()
    return {"isAuthorized": token == expected}
