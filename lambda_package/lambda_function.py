import logging
import os
import datetime
import json
import boto3
import redis
from authentication import auth


region = os.environ.get('REGION')
user_pool_id = os.environ.get('USER_POOL_ID') 
app_client_id = os.environ.get('APP_CLIENT_ID')
user_pool_domain = os.environ.get('USER_POOL_DOMAIN') 
redis_host_url = os.environ.get('REDIS_HOST_URL') 
redis_host_port = os.environ.get('REDIS_PORT') 
secret_name = os.environ.get('SECRET_NAME') 
quota_attribute = os.environ.get('QUOTA_ATTRIBUTE')


# Setting Logging
logger = logging.getLogger(__name__)
LOG_LEVEL = os.environ.get('LOG_LEVEL','INFO')
logger.setLevel(LOG_LEVEL)


# Fetch redis auth token from SecretsManager
def retrieve_token(secret_name: str) -> str:
    sm = boto3.client('secretsmanager')
    secret = sm.get_secret_value(SecretId=secret_name)
    token = json.loads(secret['SecretString'])
    return token['auth_token']


# Response Template
def response(isAuthorized: bool) -> dict:
    policy = {
                "isAuthorized": isAuthorized
             }

    return policy


# Calculates amount of time in sec till midnight
def time_until_midnight(dt=None) -> int:
    if dt is None:
        dt = datetime.datetime.now()
    return ((24 - dt.hour - 1) * 60 * 60) + ((60 - dt.minute - 1) * 60) + (60 - dt.second)


# Open Redis Connection
r = redis.StrictRedis(host=redis_host_url, port=redis_host_port, password=retrieve_token(secret_name),
                      decode_responses=True, ssl=True)


def lambda_handler(event, context):
    access_token = event["authorizationToken"]
    claim = auth(access_token, region, user_pool_id, app_client_id,user_pool_domain)
    username = claim["username"]
    quota = int(claim[quota_attribute])
    count = r.hget(username, 'count')

    if count:
        if quota > int(count):
                r.hincrby(username, 'count', 1)
                return response(True)

        logger.info(f"User {username} exceeded daily quota of {quota}")
        return response(False)

    expiration = int(time_until_midnight())
    r.hset(username, 'count', 1)
    r.expire(username, expiration)
    return response(True)
