import json
import os

import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

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

def send_notification(
    fcm_token: str,
    task: str,
    msg: str,
):
    print("FCM TOKEN RECEIVED:", repr(fcm_token))
    print("FCM TOKEN TYPE:", type(fcm_token))

    if not fcm_token:
        return

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=task,
                body=msg,
            ),
            token=fcm_token.strip(),
        )

        response = messaging.send(message)

        print(f"✅ Notification sent: {response}")
    except messaging.UnregisteredError:
        print(f"[FCM WARNING] Token is unregistered/expired: {fcm_token}")
        # Optional: You can clear invalid tokens from DB here if needed
    except FirebaseError as e:
        print(f"[FCM ERROR] Firebase error sending notification: {e}")
    except Exception as e:
        print(f"[FCM ERROR] Unexpected error sending notification: {e}")
    

def send_multiple_notifications(
    fcm_tokens: list[str],
    task: str,
    msg: str,
):
    if not fcm_tokens:
        print("No FCM tokens to send to.")
        return
    try:
        messages = [
            messaging.Message(
                notification=messaging.Notification(
                    title=task,
                    body=msg,
                ),
                token=token,
            )
            for token in fcm_tokens
        ]

        if not messages:
            return

        response = messaging.send_each(messages)

        print(f"Success count: {response.success_count}")
        print(f"Failure count: {response.failure_count}")

        for result in response.responses:
            if not result.success:
                print(f"Failed: {result.exception}")
    except Exception as e:
        print(f"[FCM ERROR] Failed to send multicast notification: {e}")
        return