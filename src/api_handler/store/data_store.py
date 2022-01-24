##Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
##SPDX-License-Identifier: MIT-0
import boto3
from typing import List, Dict, Union

dynamodb = boto3.resource("dynamodb")


class ProductStore:
    def __init__(self, table_name: str) -> None:
        self._table = dynamodb.Table(table_name)

    def get_products(self) -> List[Dict]:
        response = self._table.scan(Limit=20)
        return response["Items"]

    def put_product(self, product: Dict) -> None:
        self._table.put_item(
            Item={
                "id": product["id"],
                "name": product["name"],
                "price": str(product["price"]),
            }
        )

    def get_product(self, id: int) -> Union[Dict, None]:
        response = self._table.get_item(Key={"id": id})
        if "Item" in response:
            return response["Item"]
        else:
            return None

    def delete_product(self, id: int) -> None:
        self._table.delete_item(Key={"id": id})
