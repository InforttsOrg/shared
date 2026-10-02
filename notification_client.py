#!/usr/bin/env python3
"""
Shared Infortts Push Notification Client
Used across Mitochondria, Forensics, Meeseeks, Care4U, and all Infortts ecosystem apps
to dispatch multi-channel push alerts, macro news, trade setups, and newsletters.
"""

import os
import json
import urllib.request
import ssl

PUSH_GATEWAY_URL = os.getenv("PUSH_GATEWAY_URL", "http://127.0.0.1:8035/api/v1/notify")

def send_push_notification(title: str, body: str, topic: str = "trades", channels=None, priority="high", url="https://client.infortts.site", data=None):
    """Dispatches a notification to the Infortts notification gateway."""
    if channels is None:
        channels = ["in_app", "web_push", "mobile_push", "telegram"]
        
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
        # Fallback to direct ntfy push if local gateway is warming up
        try:
            ntfy_url = "https://ntfy.sh"
            p_level = 5 if priority == "critical" else (4 if priority == "high" else 3)
            tags = ["chart_with_upwards_trend", "bell"] if "trade" in topic or "scalp" in topic else ["newspaper", "loudspeaker"]
            ntfy_payload = {
                "topic": f"infortts_{topic}",
                "title": title,
                "message": body,
                "priority": p_level,
                "tags": tags,
                "click": url
            }
            req2 = urllib.request.Request(
                ntfy_url,
                data=json.dumps(ntfy_payload).encode("utf-8"),
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            ctx2 = ssl._create_unverified_context()
            with urllib.request.urlopen(req2, context=ctx2, timeout=5) as resp2:
                resp_data = json.loads(resp2.read().decode())
                return {"status": "dispatched", "channel": "mobile_push_hub", "topic": topic, "id": resp_data.get("id")}
        except Exception as err:
            return {"status": "fallback_error", "error": str(err), "topic": topic}

# --- Specialized Helpers for Mitochondria & Macro Trading ---

def notify_macro_news(title: str, impact: str, country: str, details: str, forecast=None, actual=None, previous=None):
    """Dispatches ForexFactory / Fed / RBI / FOMC / Unemployment / CPI rate alert."""
    badge = "🔴 RED FOLDER" if impact.upper() in ["HIGH", "CRITICAL", "RED"] else "🟡 ORANGE FOLDER"
    body = f"[{country}] {badge}: {details}\n"
    if actual is not None and forecast is not None:
        body += f"Actual: {actual} (Forecast: {forecast}, Prev: {previous})\n"
    body += f"Momentum scalp trigger scanning active on 1m chart."
    
    return send_push_notification(
        title=f"⚡ Macro Event: {title}",
        body=body,
        topic="mitochondria_news_macro",
        priority="critical" if "RED" in badge else "high",
        url="https://client.infortts.site",
        data={
            "type": "macro_news",
            "impact": impact,
            "country": country,
            "actual": actual,
            "forecast": forecast
        }
    )

def notify_indian_stocks(symbol: str, event_title: str, price_impact: str, details: str):
    """Dispatches Indian NSE/BSE stocks & RBI news updates."""
    body = f"NSE/BSE [{symbol}]: {details}\nPrice Reaction: {price_impact}"
    return send_push_notification(
        title=f"🇮🇳 Indian Markets: {event_title}",
        body=body,
        topic="mitochondria_indian_stocks",
        priority="high",
        url="https://client.infortts.site",
        data={"type": "indian_stocks", "symbol": symbol}
    )

def notify_trade_setup(symbol: str, timeframe: str, setup_name: str, bias: str, entry: float, sl: float, tp: float, confluence_reason: str):
    """Dispatches multi-timeframe A+ trade setup alerts."""
    body = f"Symbol: {symbol} ({timeframe})\nBias: {bias.upper()} (A+ Setup: {setup_name})\nEntry: {entry} | SL: {sl} | TP: {tp}\nConfluence: {confluence_reason}"
    return send_push_notification(
        title=f"🎯 A+ Setup Identified: {symbol} {bias.upper()}",
        body=body,
        topic="mitochondria_trade_setups",
        priority="critical",
        url="https://client.infortts.site",
        data={
            "type": "trade_setup",
            "symbol": symbol,
            "timeframe": timeframe,
            "bias": bias,
            "entry": entry,
            "sl": sl,
            "tp": tp
        }
    )

def notify_momentum_scalp_trigger(symbol: str, direction: str, delta_volume_surge: str, spread: float, entry_price: float):
    """Dispatches immediate 0-15s post-news momentum scalp execution alert."""
    body = f"Breaking News Momentum Scalp Triggered!\nSymbol: {symbol}\nDirection: {direction.upper()}\nEntry: {entry_price} (Spread: {spread} pips)\nVolume Surge: {delta_volume_surge}\nOutbox state: Dispatched to MT5 Single Executor."
    return send_push_notification(
        title=f"⚡ NEWS SCALP FIRED: {symbol} {direction.upper()}",
        body=body,
        topic="mitochondria_scalp_orders",
        priority="critical",
        url="https://client.infortts.site",
        data={
            "type": "momentum_scalp",
            "symbol": symbol,
            "direction": direction,
            "entry": entry_price
        }
    )

def notify_newsletter_digest(edition: str, subject: str, headline: str, summary: str, read_url="https://docs.infortts.site"):
    """Dispatches periodic newsletter and market intelligence digest."""
    body = f"{headline}\n\n{summary}\n\nRead full edition: {read_url}"
    return send_push_notification(
        title=f"📬 Infortts Intel [{edition}]: {subject}",
        body=body,
        topic="ecosystem_newsletter",
        channels=["in_app", "email_newsletter", "telegram"],
        priority="normal",
        url=read_url,
        data={"type": "newsletter", "edition": edition}
    )

def broadcast_all_apps_notification(title: str, body: str, data=None):
    """Dispatches high-priority push notifications across all Infortts ecosystem apps."""
    topics = ["mitochondria", "meeseeks", "care4u", "yorgia", "artits", "ikaria", "all_apps"]
    results = {}
    for t in topics:
        results[t] = send_push_notification(title=title, body=body, topic=t, data=data)
    return results

if __name__ == "__main__":
    print("[*] Running Notification Client Self-Test...")
    res1 = notify_macro_news(
        title="US Non-Farm Payrolls & Unemployment Rate",
        impact="Red",
        country="USD",
        details="Non-Farm Employment Change & Unemployment Rate release imminent at 12:30 GMT.",
        forecast="165K",
        actual="142K",
        previous="114K"
    )
    print("Macro News Test:", res1)
