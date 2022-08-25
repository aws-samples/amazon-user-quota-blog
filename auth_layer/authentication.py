import cognitojwt
import requests
import json


def auth(access_token: str, region: str, user_pool_id: str, app_client_id: str, user_pool_domain: str) -> dict:
    user_info_endpoint = f"https://{user_pool_domain}.{region}.amazoncognito.com/oauth2/userInfo"
    verified_claims: dict = cognitojwt.decode(
        access_token,
        region,
        user_pool_id,
        app_client_id=app_client_id,  
        testmode=False 
    )

    if verified_claims:
        user_info = requests.get(user_info_endpoint, headers={"Authorization": f"Bearer {access_token}"})
        return json.loads(user_info.text)