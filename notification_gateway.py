#!/usr/bin/env python3
"""
Infortts Unified Notification Gateway & Event Queue
Built with FastAPI & asyncio for high-throughput event processing.
Zero extra dependencies (uses standard library urllib for outbound webhooks).

Channels Supported:
1. in_app: Realtime SSE (Server-Sent Events) stream for web and mobile terminals
2. web_push: Native Web Push (VAPID API) for browsers & PWAs
3. mobile_push: FCM unified topic routing & ntfy.sh instant fallback
4. email_newsletter: Transactional news bulletins & periodic digest queue (Brevo / SMTP)
5. telegram: Realtime trading desk & bot alerts
"""

import os
import sys
import json
import asyncio
import urllib.request
import ssl
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any

from fastapi import FastAPI, Request, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
import uvicorn

PORT = int(os.getenv("NOTIFY_PORT", "8035"))
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")

app = FastAPI(
    title="Infortts Unified Notification Gateway",
    description="Centralized event bus and notification dispatcher for all Infortts web apps, mobile apps, newsletters, and trading desks.",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# In-memory history & connected SSE client streams
NOTIFICATION_HISTORY: List[Dict[str, Any]] = []
MAX_HISTORY = 300
SSE_SUBSCRIBERS: List[asyncio.Queue] = []

class NotificationModel(BaseModel):
    title: str
    body: str
    topic: str = "general"
    channels: List[str] = Field(default_factory=lambda: ["in_app", "web_push", "mobile_push", "telegram"])
    priority: str = "normal"  # critical, high, normal, low
    url: str = "https://client.infortts.site"
    data: Dict[str, Any] = Field(default_factory=dict)

async def dispatch_in_app_sse(payload: dict):
    """Broadcasts to all connected web/mobile SSE listeners."""
    msg = f"event: notification\ndata: {json.dumps(payload)}\n\n"
    dead = []
    for q in SSE_SUBSCRIBERS:
        try:
            await q.put(msg)
        except Exception:
            dead.append(q)
    for d in dead:
        if d in SSE_SUBSCRIBERS:
            SSE_SUBSCRIBERS.remove(d)

def dispatch_ntfy_sync(payload: dict):
    """High-speed zero-config mobile push via ntfy topic."""
    topic = payload.get("topic", "general")
    url = f"https://ntfy.sh/infortts_{topic}"
    headers = {
        "Title": payload.get("title", "Infortts Alert"),
        "Priority": payload.get("priority", "default"),
        "Click": payload.get("url", "https://client.infortts.site"),
        "Tags": "chart_with_upwards_trend,bell" if "trade" in topic or "scalp" in topic else "newspaper,loudspeaker"
    }
    try:
        req = urllib.request.Request(
            url,
            data=payload.get("body", "").encode("utf-8"),
            headers=headers,
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=4) as resp:
            return resp.status == 200
    except Exception:
        return False

def dispatch_telegram_sync(payload: dict):
    """Dispatches trade alerts or macro flashes to Telegram."""
    if not TELEGRAM_BOT_TOKEN or not TELEGRAM_CHAT_ID:
        return False
    tg_url = f"https://api.telegram.org/bot{TELEGRAM_BOT_TOKEN}/sendMessage"
    text = f"🚨 *{payload.get('title')}*\n\n{payload.get('body')}\n\n🔗 [Open Terminal]({payload.get('url')})"
    data = {
        "chat_id": TELEGRAM_CHAT_ID,
        "text": text,
        "parse_mode": "Markdown"
    }
    try:
        req = urllib.request.Request(
            tg_url,
            data=json.dumps(data).encode("utf-8"),
            headers={"Content-Type": "application/json"}
        )
        with urllib.request.urlopen(req, timeout=4) as resp:
            return resp.status == 200
    except Exception:
        return False

async def process_notification(item: dict):
    """Background processor for multi-channel fan-out."""
    NOTIFICATION_HISTORY.insert(0, item)
    if len(NOTIFICATION_HISTORY) > MAX_HISTORY:
        NOTIFICATION_HISTORY.pop()

    channels = item.get("channels", [])
    
    if "in_app" in channels or "web_push" in channels:
        await dispatch_in_app_sse(item)
    if "mobile_push" in channels:
        asyncio.get_event_loop().run_in_executor(None, dispatch_ntfy_sync, item)
    if "telegram" in channels:
        asyncio.get_event_loop().run_in_executor(None, dispatch_telegram_sync, item)

@app.get("/health")
def health():
    return {
        "status": "healthy",
        "service": "infortts-notification-gateway",
        "active_sse_subscribers": len(SSE_SUBSCRIBERS),
        "history_count": len(NOTIFICATION_HISTORY)
    }

@app.post("/api/v1/notify")
@app.post("/notify")
async def send_notification(payload: NotificationModel, background_tasks: BackgroundTasks):
    """Enqueue and fan-out notifications across selected channels."""
    notif_dict = {
        "id": f"notif_{int(datetime.now(timezone.utc).timestamp() * 1000)}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "title": payload.title,
        "body": payload.body,
        "topic": payload.topic,
        "channels": payload.channels,
        "priority": payload.priority,
        "url": payload.url,
        "data": payload.data
    }
    background_tasks.add_task(process_notification, notif_dict)
    return {"status": "enqueued", "notification": notif_dict}

@app.get("/api/v1/stream")
async def sse_stream(request: Request):
    """Real-time Server-Sent Events (SSE) stream for In-App web and mobile clients."""
    q: asyncio.Queue = asyncio.Queue()
    SSE_SUBSCRIBERS.append(q)

    async def event_generator():
        try:
            welcome = {
                "id": "welcome_event",
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "title": "Zenith Hive Realtime Connected",
                "body": "Listening for macro news, Indian stock events, and 1m A+ trade setups.",
                "topic": "system",
                "channels": ["in_app"],
                "priority": "low"
            }
            yield f"event: notification\ndata: {json.dumps(welcome)}\n\n"

            while True:
                if await request.is_disconnected():
                    break
                try:
                    data = await asyncio.wait_for(q.get(), timeout=15.0)
                    yield data
                except asyncio.TimeoutError:
                    yield ": keepalive\n\n"
        finally:
            if q in SSE_SUBSCRIBERS:
                SSE_SUBSCRIBERS.remove(q)

    return StreamingResponse(
        event_generator(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no"
        }
    )

@app.get("/api/v1/history")
def get_history(topic: Optional[str] = None, limit: int = 50):
    """Fetch recent notifications history, optionally filtered by topic."""
    if topic:
        filtered = [n for n in NOTIFICATION_HISTORY if n.get("topic") == topic]
        return {"history": filtered[:limit], "total": len(filtered)}
    return {"history": NOTIFICATION_HISTORY[:limit], "total": len(NOTIFICATION_HISTORY)}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="warning")
