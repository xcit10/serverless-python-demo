##Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
##SPDX-License-Identifier: MIT-0
import os
import json

from utils import ProductStore

product_store = ProductStore(os.getenv("TABLE"))


def lambda_handler(event, context):
    products = product_store.get_products()
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps({"products": products}),
    }
