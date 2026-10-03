#!/usr/bin/env python3
"""
Infortts Unified Notification Gateway & Event Queue
Built with FastAPI & asyncio for high-throughput event processing.
Persistent SQLite storage via notification_db.py.

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

from fastapi import FastAPI, Request, BackgroundTasks, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from pydantic import BaseModel, Field
import uvicorn

import notification_db

PORT = int(os.getenv("NOTIFY_PORT", "8035"))
TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN", "")
TELEGRAM_CHAT_ID = os.getenv("TELEGRAM_CHAT_ID", "")
BREVO_API_KEY = os.getenv("BREVO_API_KEY", "")

app = FastAPI(
    title="Infortts Unified Notification Gateway",
    description="Centralized event bus and notification dispatcher for all Infortts web apps, mobile apps, newsletters, and trading desks.",
    version="1.1.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

SSE_SUBSCRIBERS: List[asyncio.Queue] = []

class NotificationModel(BaseModel):
    title: str
    body: str
    topic: str = "general"
    category: Optional[str] = None
    symbol: Optional[str] = None
    channels: List[str] = Field(default_factory=lambda: ["in_app", "web_push", "mobile_push", "telegram"])
    priority: str = "normal"  # critical, high, normal, low
    url: str = "https://client.infortts.site"
    data: Dict[str, Any] = Field(default_factory=dict)

class MarkReadModel(BaseModel):
    id: Optional[str] = None
    ids: Optional[List[str]] = None
    category: Optional[str] = None

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
    """Background processor for SQLite persistence & multi-channel fan-out."""
    # 1. Insert into persistent SQLite DB
    stored = notification_db.insert_notification(item)
    
    channels = item.get("channels", [])
    
    # 2. Fan-out to channels
    if "in_app" in channels or "web_push" in channels:
        await dispatch_in_app_sse(stored)
    if "mobile_push" in channels:
        asyncio.get_event_loop().run_in_executor(None, dispatch_ntfy_sync, stored)
    if "telegram" in channels:
        asyncio.get_event_loop().run_in_executor(None, dispatch_telegram_sync, stored)

@app.get("/health")
def health():
    stats = notification_db.get_notifications(limit=1)
    return {
        "status": "healthy",
        "service": "infortts-notification-gateway",
        "active_sse_subscribers": len(SSE_SUBSCRIBERS),
        "total_notifications": stats.get("total_count", 0),
        "unread_count": stats.get("unread_count", 0)
    }

@app.post("/api/v1/notify")
@app.post("/notify")
async def send_notification(payload: NotificationModel, background_tasks: BackgroundTasks):
    """Enqueue and fan-out notifications across selected channels with DB persistence."""
    notif_dict = {
        "id": f"notif_{int(datetime.now(timezone.utc).timestamp() * 1000)}",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "title": payload.title,
        "body": payload.body,
        "topic": payload.topic,
        "category": payload.category,
        "symbol": payload.symbol,
        "channels": payload.channels,
        "priority": payload.priority,
        "url": payload.url,
        "data": payload.data,
        "is_read": False
    }
    background_tasks.add_task(process_notification, notif_dict)
    return {"status": "enqueued", "notification": notif_dict}

@app.get("/api/v1/notifications")
@app.get("/api/notifications")
def get_notifications_api(
    category: Optional[str] = Query(None),
    topic: Optional[str] = Query(None),
    unread_only: bool = Query(False),
    limit: int = Query(50, ge=1, le=200),
    offset: int = Query(0, ge=0)
):
    """Fetch notifications from persistent SQLite DB with category and read status filtering."""
    data = notification_db.get_notifications(
        category=category,
        topic=topic,
        unread_only=unread_only,
        limit=limit,
        offset=offset
    )
    return {
        "status": "ok",
        "notifications": data["notifications"],
        "unread_count": data["unread_count"],
        "total_count": data["total_count"]
    }

@app.post("/api/v1/notifications/mark_read")
@app.post("/api/notifications/mark_read")
def mark_read(payload: MarkReadModel):
    """Mark one or more notifications as read in SQLite DB."""
    if payload.id:
        success = notification_db.mark_notification_as_read(payload.id)
        return {"status": "ok", "marked_id": payload.id, "success": success}
    if payload.ids:
        count = 0
        for nid in payload.ids:
            if notification_db.mark_notification_as_read(nid):
                count += 1
        return {"status": "ok", "marked_count": count}
    if payload.category:
        count = notification_db.mark_all_notifications_as_read(payload.category)
        return {"status": "ok", "marked_count": count, "category": payload.category}
    
    # Fallback: mark all
    count = notification_db.mark_all_notifications_as_read()
    return {"status": "ok", "marked_count": count}

@app.post("/api/v1/notifications/mark_all_read")
@app.post("/api/notifications/mark_all_read")
def mark_all_read(category: Optional[str] = Query(None)):
    """Mark all notifications as read in SQLite DB."""
    count = notification_db.mark_all_notifications_as_read(category)
    return {"status": "ok", "marked_count": count}

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
                "title": "Infortts Swarm Realtime Stream Connected",
                "body": "Listening for Indian stocks, macro releases, and trade executions.",
                "topic": "system",
                "category": "SYSTEM",
                "channels": ["in_app"],
                "priority": "low",
                "is_read": True
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
    """Legacy compatibility endpoint pointing to SQLite DB."""
    data = notification_db.get_notifications(topic=topic, limit=limit)
    return {"history": data["notifications"], "total": data["total_count"], "unread_count": data["unread_count"]}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="warning")
