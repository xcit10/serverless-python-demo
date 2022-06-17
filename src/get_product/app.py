##Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
##SPDX-License-Identifier: MIT-0
import os
import json

from utils import ProductStore


product_store = ProductStore(os.getenv("TABLE"))


def lambda_handler(event, context):
    if "id" not in event["pathParameters"]:
        return {
            "statusCode": 400,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Missing 'id' parameter in path"}),
        }

    product = product_store.get_product(event["pathParameters"]["id"])

    if product:
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(product),
        }
    else:
        return {
            "statusCode": 404,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"message": "Product not found"}),
        }
