##Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
##SPDX-License-Identifier: MIT-0

STACK_NAME=serverless-python-demo

API_URL=$(aws cloudformation describe-stacks --stack-name $STACK_NAME \
  --query 'Stacks[0].Outputs[?OutputKey==`ServerlessDemoApi`].OutputValue' \
  --output text)

echo $API_URL

artillery run load-test.yml --target "$API_URL"
