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
            "body": json.dumps({"message": "Missing 'id' in parameter path"}),
        }

    product_store.delete_product(event["pathParameters"]["id"])
    
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"message": "Product deleted"}),
    }
