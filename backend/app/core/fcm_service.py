import json
import os
from urllib import response

import firebase_admin
from firebase_admin import credentials, messaging

if not firebase_admin._apps:
    config = os.getenv("FIREBASE_CREDENTIALS")

    if not config:
        raise ValueError(
            "FIREBASE_CREDENTIALS is missing"
        )

    service_account = json.loads(config)

    service_account["private_key"] = (
        service_account["private_key"].replace("\\n", "\n")
    )

    cred = credentials.Certificate(service_account)

    firebase_admin.initialize_app(cred)
#* ----- MAIN Send Notification Function ----------

def send_notification(fcm_token:str , task:str, msg:str):
    msg = messaging.Message(
        notification=messaging.Notification(
            title=task,
            body=msg,
            
        ),
        token=fcm_token
    )
    messaging.send(msg)
    print(response.success_count)
    print(response.failure_count)



def send_multiple_notifications(fcm_tokens:list ,task:str, msg:str):
    message = messaging.MulticastMessage(
    notification=messaging.Notification(
        title=task,
        body=msg,
    ),
    tokens=fcm_tokens,   # list[str]
)

    messaging.send_each_for_multicast(message)
    print(response.success_count)
    print(response.failure_count)