# Building a user quota enforcement on AWS AppSync with Lambda authorizer
API Quotas define the valid amount of calls available for a consumer during a specific amount of time. Enforcing quotas protects your API from unintentional abuse, minimizes data exfiltration and protects your resources from excessive usage. Beyond the mentioned security benefits, it can also unlock your capabilities to monetize the digital assets sitting behind the API. This project showcases building blocks for applying daily user quotas on AWS AppSync using the Lambda Authorizer. ElastiCache for Redis, thanks to it's sub-millisecond latency, is used to track the call count in real time. 

## Solution Overview
The backend is hosted on Amazon AppSync and uses GraphQL as the connector to the DynamoDB database where the data will live. Amazon Cognito User Pool serves as the OIDC identity provider. The Lambda authorizer provides authentication, authorization and quota enforecement per user at the AppSync API. The authentication logic is provided by a Lambda Layer where [Cognitojwt](https://pypi.org/project/cognitojwt/) library and the auth method are hosted. Current call count is tracked via ElasticCache for Redis. Both the Lambda functions and Redis cluster sit in a VPC on a private subnet. Once deployed, this solution will allow Cognito user pool users to log in and consume the data.



## Blogpost URL
[How to enforce user quota on AWS AppSync with Lambda authorizer](https://aws.amazon.com/blogs/mobile/how-to-enforce-user-quota-on-aws-appsync-with-lambda-authorizer/)

## Architecture

![Alt text](./Architecture.png?raw=true "Architecture Diagram")

## Resource Deployment

The cloudformation stack will create the following resources:
- AppSync GraphQL API
- DynamoDB Table
- Cognito User Pool
- Lambda Authorization function
- Lambda Layer containing authentication logic
- Redis Cluster
- Security Groups
- IAM Roles & Policies

### Parameters:
- **STACK_NAME** - CloudFormation stack name
- **AWS_REGION** - AWS region where the solution will be deployed
- **AWS_PROFILE** - Named profile that will apply to the AWS CLI command
- **ARTEFACT_S3_BUCKET** - S3 bucket where the infrastructure code will be stored. (*The bucket must be created in the same region where the solution lives*)
- **VPC** - VPC id where the Lambda function and redis cluster will be deployed
- **SUBNET_A** - Private subnet id where the Lambda function and redis node will be deployed
- **SUBNET_B** - Private subnet id where the Lambda function and redis node will be deployed

### Outputs:

- GraphQLUrl
- CognitoUserPoolId
- CognitoAppClientId
- CognitoAccesstokenUrl
- CognitoAuthUrl
- DynamoDBTableName

## Deployment Commands
All deployments are done using bash scripts, in this case we use the following commands:
 - ```./deployment_scripts/deploy.sh```    -  Packages, builds and deploys the local artifacts that your AWS CloudFormation template (e.g: cfn_template.yaml) is referencing

   ```bash
   ./deployment_scripts/deploy.sh STACK_NAME \
   ARTEFACT_S3_BUCKET \
   AWS_PROFILE AWS_REGION \
   SUBNET_A SUBNET_B \
   VPC
   ```

 - ```./deployment_scripts/destroy.sh```   -  Destroys the CloudFormation Stack you created in the deployment above (e.g: cfnstackdeployment)
   ```bash
   ./deployment_scripts/destroy.sh STACK_NAME \
   AWS_PROFILE AWS_REGION


## Upload data into DynamoDB Table

Run the python script ```batch_upload_ddb.py``` to upload the sample data ```moviedata.json``` into the DynamoDB Table

```bash
python batch_upload_ddb.py -t DynamoDBTableName \
-p AWS_PROFILE -r AWS_REGION \
-f moviedata.json
```

## Test
You may test the solution via [postman](https://www.postman.com/). In [test](./test/) you can find the [postman collection](https://learning.postman.com/docs/getting-started/creating-the-first-collection/) json file with all the necessary configurations to authenticate and perform the GraphQL query. Once [imported](https://learning.postman.com/docs/getting-started/importing-and-exporting-data/#importing-postman-data) make sure to fill the [variables](https://learning.postman.com/docs/sending-requests/variables/) in the collection. All values will be outputted from ```./deployment_scripts/deploy.sh``` except for the **CognitoAppClientSecret** which you have to fetch from the Cognito console in the [app client](https://docs.aws.amazon.com/cognito/latest/developerguide/user-pool-settings-client-apps.html) after the deployment.

## Considerations
- Cognito
  - Make sure the stack name is all lowercase otherwise it will fail deployment. This comes due to the following configuration:
    ```yaml
    Domain:
      Fn::Sub: ${AWS::StackName}-${CognitoDomain}
    ```
- Network:
  - Select SubnetA and SubnetB as private subnets
  - Have a Public NAT GW as endpoint for the 0.0.0.0/0 in your Subnet(s) routing table(s)

## Security

See [CONTRIBUTING](CONTRIBUTING.md#security-issue-notifications) for more information.

## License

This library is licensed under the MIT-0 License. See the [LICENSE](LICENSE) file.
