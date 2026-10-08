#!/usr/bin/env python3
"""
notification_db.py — Persistent SQLite storage for Infortts Multi-Channel Notifications.
Stores all inbound news, Indian stock events, macro releases, trade setups, and system alerts.
Supports querying by topic, pagination, unread counters, and mark-as-read updates.
"""

import os
import json
import sqlite3
import threading
from datetime import datetime, timezone
from typing import List, Dict, Any, Optional

def _resolve_db_path():
    env_path = os.getenv("NOTIFICATION_DB_PATH")
    if env_path:
        return env_path
    
    # Try user home dir first
    home_db = os.path.expanduser("~/.infortts_notifications.db")
    try:
        c = sqlite3.connect(home_db, timeout=1.0)
        c.close()
        return home_db
    except Exception:
        pass
    
    # Fallback to local shared directory
    shared_db = os.path.join(os.path.dirname(os.path.abspath(__file__)), "notifications.db")
    try:
        c = sqlite3.connect(shared_db, timeout=1.0)
        c.close()
        return shared_db
    except Exception:
        pass

    return "/tmp/infortts_notifications.db"

DB_PATH = _resolve_db_path()
_LOCK = threading.RLock()

def get_db_connection() -> sqlite3.Connection:
    conn = sqlite3.connect(DB_PATH, timeout=15.0)
    conn.row_factory = sqlite3.Row
    return conn

def init_db():
    with _LOCK:
        conn = get_db_connection()
        try:
            with conn:
                conn.execute("""
                    CREATE TABLE IF NOT EXISTS notifications (
                        id TEXT PRIMARY KEY,
                        timestamp TEXT NOT NULL,
                        title TEXT NOT NULL,
                        body TEXT NOT NULL,
                        topic TEXT NOT NULL,
                        category TEXT NOT NULL,
                        symbol TEXT,
                        priority TEXT NOT NULL DEFAULT 'normal',
                        is_read INTEGER NOT NULL DEFAULT 0,
                        url TEXT,
                        data TEXT
                    )
                """)
                conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_ts ON notifications (timestamp DESC)")
                conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_topic ON notifications (topic)")
                conn.execute("CREATE INDEX IF NOT EXISTS idx_notif_read ON notifications (is_read)")
        finally:
            conn.close()

# Auto-initialize DB on import
init_db()

def _infer_category(topic: str, data: dict) -> str:
    topic_l = (topic or "").lower()
    if "indian" in topic_l or "stock" in topic_l or "nse" in topic_l or "bse" in topic_l:
        return "INDIAN_STOCKS"
    if "macro" in topic_l or "news" in topic_l or "forex" in topic_l or "fomc" in topic_l or "cpi" in topic_l:
        return "MACRO"
    if "trade" in topic_l or "scalp" in topic_l or "setup" in topic_l or "signal" in topic_l:
        return "TRADING"
    if "newsletter" in topic_l or "intel" in topic_l:
        return "NEWSLETTER"
    return "SYSTEM"

def insert_notification(notif: Dict[str, Any]) -> Dict[str, Any]:
    """Inserts a notification into SQLite DB."""
    nid = notif.get("id") or f"notif_{int(datetime.now(timezone.utc).timestamp() * 1000)}"
    ts = notif.get("timestamp") or datetime.now(timezone.utc).isoformat()
    title = notif.get("title", "")
    body = notif.get("body", "")
    topic = notif.get("topic", "general")
    data_dict = notif.get("data") or {}
    category = notif.get("category") or _infer_category(topic, data_dict)
    symbol = notif.get("symbol") or data_dict.get("symbol") or ""
    priority = notif.get("priority", "normal")
    is_read = 1 if notif.get("is_read") in (1, True, "1", "true") else 0
    url = notif.get("url", "https://client.infortts.site")
    data_str = json.dumps(data_dict) if isinstance(data_dict, dict) else str(data_dict)

    with _LOCK:
        conn = get_db_connection()
        try:
            with conn:
                conn.execute("""
                    INSERT OR REPLACE INTO notifications 
                    (id, timestamp, title, body, topic, category, symbol, priority, is_read, url, data)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                """, (nid, ts, title, body, topic, category, symbol, priority, is_read, url, data_str))
        finally:
            conn.close()

    return {
        "id": nid,
        "timestamp": ts,
        "title": title,
        "body": body,
        "topic": topic,
        "category": category,
        "symbol": symbol,
        "priority": priority,
        "is_read": bool(is_read),
        "url": url,
        "data": data_dict
    }

def get_notifications(
    category: Optional[str] = None,
    topic: Optional[str] = None,
    unread_only: bool = False,
    limit: int = 50,
    offset: int = 0
) -> Dict[str, Any]:
    """Queries notifications with filtering and unread count."""
    with _LOCK:
        conn = get_db_connection()
        try:
            conditions = []
            params = []

            if category and category.upper() != "ALL":
                conditions.append("category = ?")
                params.append(category.upper())

            if topic:
                conditions.append("topic = ?")
                params.append(topic)

            if unread_only:
                conditions.append("is_read = 0")

            where_clause = f"WHERE {' AND '.join(conditions)}" if conditions else ""

            # Fetch rows
            query = f"""
                SELECT id, timestamp, title, body, topic, category, symbol, priority, is_read, url, data
                FROM notifications
                {where_clause}
                ORDER BY timestamp DESC
                LIMIT ? OFFSET ?
            """
            rows = conn.execute(query, (*params, limit, offset)).fetchall()

            # Unread total across DB
            unread_count = conn.execute("SELECT COUNT(*) FROM notifications WHERE is_read = 0").fetchone()[0]
            total_count = conn.execute("SELECT COUNT(*) FROM notifications").fetchone()[0]

            results = []
            for r in rows:
                try:
                    d = json.loads(r["data"]) if r["data"] else {}
                except Exception:
                    d = {}
                results.append({
                    "id": r["id"],
                    "timestamp": r["timestamp"],
                    "title": r["title"],
                    "body": r["body"],
                    "topic": r["topic"],
                    "category": r["category"],
                    "symbol": r["symbol"],
                    "priority": r["priority"],
                    "is_read": bool(r["is_read"]),
                    "url": r["url"],
                    "data": d
                })

            return {
                "notifications": results,
                "unread_count": unread_count,
                "total_count": total_count
            }
        finally:
            conn.close()

def mark_notification_as_read(notif_id: str) -> bool:
    """Marks a single notification as read."""
    with _LOCK:
        conn = get_db_connection()
        try:
            with conn:
                conn.execute("UPDATE notifications SET is_read = 1 WHERE id = ?", (notif_id,))
            return True
        except Exception:
            return False
        finally:
            conn.close()

def mark_all_notifications_as_read(category: Optional[str] = None) -> int:
    """Marks all notifications (optionally in a category) as read."""
    with _LOCK:
        conn = get_db_connection()
        try:
            with conn:
                if category and category.upper() != "ALL":
                    cursor = conn.execute("UPDATE notifications SET is_read = 1 WHERE is_read = 0 AND category = ?", (category.upper(),))
                else:
                    cursor = conn.execute("UPDATE notifications SET is_read = 1 WHERE is_read = 0")
                return cursor.rowcount
        finally:
            conn.close()
