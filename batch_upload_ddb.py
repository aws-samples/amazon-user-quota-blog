import logging
import sys
import argparse
import decimal
import json
import boto3
from botocore.exceptions import ClientError

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stderr, level=logging.INFO)

#Fetch arguments
parser = argparse.ArgumentParser()
parser.add_argument('-p','--profile')
parser.add_argument('-f','--file')
parser.add_argument('-r','--region')
parser.add_argument('-t','--table')
args = parser.parse_args()


def my_raise(ex): 
    sys.tracebacklimit = 0
    raise ex


profile = args.profile if args.profile else my_raise(ValueError("Please pass the aws profile via -p, --profile"))
region = args.region if args.region  else "eu-west-1" and logger.info("Setting AWS region to default: eu-west-1")
table_name = args.table if args.table else my_raise(ValueError("Please provide the dynamodb table name via -t, --table"))
json_data = args.file if args.file else my_raise(ValueError("Please provide the data file via -f, --file ")) 

session = boto3.Session(profile_name=profile, region_name=region)
dynamodb = session.resource('dynamodb')
table = dynamodb.Table(table_name)


def parse_data(json_data):
    with open(json_data) as json_file:
        return json.load(json_file, parse_float = decimal.Decimal)


def fill_table(table, table_data):
    try:
        with table.batch_writer() as writer:
            for item in table_data:
                writer.put_item(Item=item)
                logger.debug(f"Movie {item['title']} added into table {table.name}")
        logger.info("Data upload complete!")
    except ClientError:
        logger.exception(f"Couldn't load data into table {table.name}.")
        raise


fill_table(table, parse_data(json_data))