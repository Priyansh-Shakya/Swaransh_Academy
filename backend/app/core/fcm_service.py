import json
import os

import firebase_admin
from firebase_admin import credentials, messaging
from firebase_admin.exceptions import FirebaseError

# -----------------------------
# Firebase Initialization
# -----------------------------
if not firebase_admin._apps:
    config = os.getenv("FIREBASE_CREDENTIALS")

    if not config:
        raise ValueError("FIREBASE_CREDENTIALS is missing")

    service_account = json.loads(config)
    service_account["private_key"] = service_account["private_key"].replace("\\n", "\n")

    cred = credentials.Certificate(service_account)
    firebase_admin.initialize_app(cred)


# Common Android High-Priority Config
# This guarantees heads-up popup banner delivery on Android 8+ devices
ANDROID_CONFIG = messaging.AndroidConfig(
    priority="high",
    notification=messaging.AndroidNotification(
        channel_id="high_importance_channel_v2",  # MUST MATCH Flutter Channel ID
        priority="high",
        default_sound=True,
    ),
)


# -----------------------------
# MAIN Send Single Notification
# -----------------------------
def send_notification(
    fcm_token: str,
    task: str,
    msg: str,
):
    print("FCM TOKEN RECEIVED:", repr(fcm_token))
    print("FCM TOKEN TYPE:", type(fcm_token))

    if not fcm_token or not fcm_token.strip():
        print("[FCM WARNING] Empty token provided.")
        return

    try:
        message = messaging.Message(
            notification=messaging.Notification(
                title=task,
                body=msg,
            ),
            android=ANDROID_CONFIG,  # Config added here
            token=fcm_token.strip(),
        )

        response = messaging.send(message)
        print(f"✅ Notification sent: {response}")

    except messaging.UnregisteredError:
        print(f"[FCM WARNING] Token is unregistered/expired: {fcm_token}")
    except FirebaseError as e:
        print(f"[FCM ERROR] Firebase error sending notification: {e}")
    except Exception as e:
        print(f"[FCM ERROR] Unexpected error sending notification: {e}")


# -----------------------------
# MAIN Send Multiple Notifications
# -----------------------------
def send_multiple_notifications(
    recipients: list[dict | str],
    task: str,
    msg: str,
):
    """
    Accepts either a list of FCM tokens (strings) OR a list of dicts/objects.
    Example dict: {"name": "Admin John", "fcm_token": "fcm_token_123"}
    """
    if not recipients:
        print("No FCM recipients to send to.")
        return

    messages = []
    metadata = []  # Keeps track of name/token pairs for logging

    for idx, item in enumerate(recipients):
        token = None
        label = f"Recipient #{idx + 1}"

        if isinstance(item, dict):
            token = item.get("fcm_token") or item.get("token")
            label = item.get("name") or item.get("email") or item.get("id") or label
        elif isinstance(item, str):
            token = item
            # Mask token for cleaner printing: "f0d75...4c73"
            label = f"Token ({token[:6]}...{token[-4:]})" if len(token) > 10 else token

        if not token or not token.strip():
            print(f"⚠️ [FCM SKIPPED] Missing token for {label}")
            continue

        messages.append(
            messaging.Message(
                notification=messaging.Notification(
                    title=task,
                    body=msg,
                ),
                android=ANDROID_CONFIG,  # Config added here
                token=token.strip(),
            )
        )
        metadata.append({"label": label, "token": token.strip()})

    if not messages:
        print("No valid messages built to send.")
        return

    try:
        # send_each replaces legacy send_multicast
        batch_response = messaging.send_each(messages)

        print("\n================ FCM BATCH RESULT ================")
        print(f"Total Sent Attempted: {len(messages)}")
        print(f"✅ Success Count:     {batch_response.success_count}")
        print(f"❌ Failure Count:     {batch_response.failure_count}")
        print("--------------------------------------------------")

        for idx, result in enumerate(batch_response.responses):
            recipient_info = metadata[idx]
            target_label = recipient_info["label"]

            if result.success:
                print(f"🟢 [SUCCESS] -> {target_label} (Msg ID: {result.message_id})")
            else:
                print(f"🔴 [FAILED]  -> {target_label} | Error: {result.exception}")

        print("==================================================\n")

    except Exception as e:
        print(f"[FCM ERROR] Failed to send multicast notification: {e}")