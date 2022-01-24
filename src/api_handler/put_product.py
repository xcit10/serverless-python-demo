##Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
##SPDX-License-Identifier: MIT-0
import os
import json

from .store.data_store import ProductStore


product_store = ProductStore(os.getenv("TABLE"))


def lambda_handler(event, context):
    if "id" not in event["pathParameters"]:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Missing 'id' parameter in path"}),
        }

    product_store.put_product(json.loads(event["body"]))

    return {
        "statusCode": 201,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "Product created"}),
    }
