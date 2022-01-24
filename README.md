## Serverless Python Demo



<p align="center">
  <img src="imgs/diagram.png" alt="Architecture diagram"/>
</p>

This is a simple serverless application built in Python. It consists of an 
[Amazon API Gateway](https://aws.amazon.com/api-gateway/) backed by four [AWS Lambda](https://aws.amazon.com/lambda/) 
functions and an [Amazon DynamoDB](https://aws.amazon.com/dynamodb/) table for storage. 

## Requirements

- [AWS CLI](https://aws.amazon.com/cli/)
- [AWS SAM CLI](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html) for deploying to the cloud
- [Python 3.9](https://python.org)
- [Artillery](https://www.artillery.io/) for load-testing the application

### Deployment

Deploy the demo to your AWS account using [AWS SAM](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/what-is-sam.html).

```bash
sam build --use-container
sam deploy --guided
```

The command `sam build --use-container` will first build and package the Lambda functions using docker. 

`sam deploy` will use AWS CloudFormation to deploy the resources to your account and output the API Gateway endpoint URL for future use in our load tests.

## Load Test

[Artillery](https://www.artillery.io/) is used to make 300 requests / second for 10 minutes to our API endpoints. You can run this
with the following command.

```bash
cd load-test
./run-load-test.sh
```

This is a demanding load test, to change the rate alter the `arrivalRate` value in `load-test.yml`.

### CloudWatch Logs Insights

Using this CloudWatch Logs Insights query you can analyse the latency of the requests made to the Lambda functions.

The query separates cold starts from other requests and then gives you p50, p90 and p99 percentiles.

```
filter @type="REPORT"
| fields greatest(@initDuration, 0) + @duration as duration, ispresent(@initDuration) as coldStart
| stats count(*) as count, min(duration) as min, pct(duration, 50) as p50, pct(duration, 90) as p90, pct(duration, 99) as p99, max(duration) as max by coldStart
```

-------------------------------------------------------------------------
| coldStart | count  |  min   |   p50    |   p90    |   p99    |  max   |
|-----------|--------|--------|----------|----------|----------|--------|
| 0         | 466633 | 3.48   | 8.2578   | 10.8157  | 18.8511  | 247.83 |
| 1         | 1092   | 672.05 | 715.3087 | 738.5569 | 763.3233 | 835.08 |
-------------------------------------------------------------------------

## 👀 With other languages

You can find implementations of this project in other languages here:

* [🦀  Rust](https://github.com/aws-samples/serverless-rust-demo)
* [☕ Java with GraalVM](https://github.com/aws-samples/serverless-graalvm-demo)
* [🐿️ Go](https://github.com/aws-samples/serverless-go-demo)
* [🤖 Kotlin](https://github.com/aws-samples/serverless-kotlin-demo)
* [Groovy](https://github.com/aws-samples/serverless-groovy-demo)
* [Typescript](https://github.com/aws-samples/serverless-typescript-demo)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the LICENSE file.

