#!/usr/bin/env python3
"""
Shared Infortts Push Notification Client
Used across Mitochondria, Forensics, Meeseeks, and Care4U to dispatch multi-channel push alerts.
"""

import os
import json
import urllib.request
import ssl

PUSH_GATEWAY_URL = os.getenv("PUSH_GATEWAY_URL", "http://127.0.0.1:8030/api/v1/notify")

def send_push_notification(title: str, body: str, topic: str = "trades", channels=None, priority="high", url="https://forensics.infortts.site/", data=None):
    if channels is None:
        channels = ["android", "web", "telegram"]
        
    payload = {
        "title": title,
        "body": body,
        "topic": topic,
        "channels": channels,
        "priority": priority,
        "url": url,
        "data": data or {}
    }
    
    try:
        req = urllib.request.Request(
            PUSH_GATEWAY_URL,
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        with urllib.request.urlopen(req, context=ctx, timeout=4) as resp:
            return json.loads(resp.read().decode())
    except Exception as e:
        # Fallback to direct Android/Telegram if microservice is warming up
        try:
            ntfy_url = f"https://ntfy.sh/infortts_{topic}"
            headers = {"Title": title.encode("utf-8"), "Priority": priority, "Click": url}
            req2 = urllib.request.Request(ntfy_url, data=body.encode("utf-8"), headers=headers, method="POST")
            with urllib.request.urlopen(req2, timeout=4) as resp2:
                pass
        except Exception:
            pass
        return {"status": "fallback_sent", "error": str(e)}

def broadcast_all_apps_notification(title: str, body: str, data=None):
    """Dispatches high-priority push notifications across all 28 Infortts ecosystem apps."""
    topics = ["mitochondria", "meeseeks", "care4u", "yorgia", "artits", "ikaria", "all_apps"]
    results = {}
    for t in topics:
        results[t] = send_push_notification(title=title, body=body, topic=t, data=data)
    return results

if __name__ == "__main__":
    res = broadcast_all_apps_notification(
        title="⚡ Emergency OTA Update Broadcast",
        body="Top-transitioning alerts & instant CDN patch sync activated across all apps.",
    )
    print("All-Apps Push dispatch result:", res)
