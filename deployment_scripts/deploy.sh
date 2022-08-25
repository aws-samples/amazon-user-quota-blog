#!/bin/bash

### chmod +x deploy.sh 

STACK_NAME=${1:?"Enter the STACK_NAME for this deployment"}
ARTEFACT_S3_BUCKET=${2:?"appsync-artefacts"}
AWS_PROFILE=${3:?"Enter the AWS_PROFILE for this deployment"}
AWS_REGION=${4:?"Enter the AWS_REGION for this deployment"}
SUBNET_A=${5:?"Enter Subnet A please before proceeding"}
SUBNET_B=${6:?"Enter Subnet B please before proceeding"}
VPC=${7:?"Enter VPC please before proceeding"}
SOURCE_TEMPLATE="cfn_template.yaml"
OUTPUT_TEMPLATE="output-template.yaml"
DEPENDENCIES=(pip3 zip aws)

function check_dependencies_mac()
{
  dependencies=$1
  for name in ${dependencies[@]};
  do
    [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name needs to be installed. Use 'brew install $name'";deps=1; }
  done
  [[ $deps -ne 1 ]] || { echo -en "\nInstall the above and rerun this script\n";exit 1; }
}

function check_dependencies_linux()
{
  dependencies=$1
  for name in ${dependencies[@]};
  do
    [[ $(which $name 2>/dev/null) ]] || { echo -en "\n$name needs to be installed. Use 'sudo apt-get install $name'";deps=1; }
  done
  [[ $deps -ne 1 ]] || { echo -en "\nInstall the above and rerun this script\n";exit 1; }
}

## Check dependencies by OS
if [ "$(uname)" == "Darwin" ]; then
    check_dependencies_mac "${DEPENDENCIES[*]}"   
elif [ "$(expr substr $(uname -s) 1 5)" == "Linux" ]; then
    check_dependencies_linux "${DEPENDENCIES[*]}"
else
  echo "Only Mac and Linux OS supported, exiting ..."
  exit 1   
fi

# 1. Prepare the Lambda + Layers and package it to S3

## Build Lambda layer
mkdir python
pip3 install -r ./auth_layer/requirements.txt --target ./python
cp ./auth_layer/authentication.py ./python
zip -r dependencies.zip python/
rm -rf python ## Cleanup

### Build Lambda
cd lambda_package
rm -rf package ## Cleanup
pip3 install -r requirements.txt --target ./package
cd package && zip -r ../lambda_package.zip . && cd -
zip -g lambda_package.zip lambda_function.py
mv lambda_package.zip ../
cd ..
rm -rf lambda_package/package ## Cleanup

aws cloudformation package --template-file ${SOURCE_TEMPLATE} \
     --s3-bucket ${ARTEFACT_S3_BUCKET} \
     --output-template-file ${OUTPUT_TEMPLATE} \
     --profile ${AWS_PROFILE} \
     --region ${AWS_REGION} &> /dev/null

if [ ! -f ${OUTPUT_TEMPLATE} ];then
     echo "Error while generating the stack template"
     exit 1
fi

#2. Deploy the CloudFormation Stack to the configured AWS Account from the generated template

aws cloudformation deploy --template-file ${OUTPUT_TEMPLATE} \
     --capabilities CAPABILITY_IAM \
     --parameter-overrides  SubnetA=${SUBNET_A} SubnetB=${SUBNET_B} VPC=${VPC}  \
     --stack-name ${STACK_NAME} \
     --region ${AWS_REGION}

aws cloudformation  describe-stacks --stack-name ${STACK_NAME} \
     --query "Stacks[0].Outputs" --output table \
     --region ${AWS_REGION}