#!/bin/bash

### chmod +x destroy.sh 
### ./deployment_scripts/destroy.sh appSyncDynamoDbLambdaAuthorizer isengard_gm eu-west-1

STACK_NAME=${1:?"Enter the STACK_NAME for this deployment"}
AWS_PROFILE=${2:?"Enter the AWS_PROFILE for this deployment"}
AWS_REGION=${3:?"Enter the AWS_REGION for this deployment"}
DEPENDENCIES=(aws)

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

aws cloudformation delete-stack --stack-name ${STACK_NAME} --profile ${AWS_PROFILE} --region ${AWS_REGION}