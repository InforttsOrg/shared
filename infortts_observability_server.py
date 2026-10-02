#!/usr/bin/env python3
"""
Infortts Centralized Observability and LLM Log Server
Central telemetry ingestion, querying, and autonomous LLM diagnostics across all Infortts applications.

Storage: PostgreSQL (infortts-postgres-shared) with automatic SQLite fallback.
Ingestion Channels:
1. HTTP REST API: POST /api/v1/logs/ingest and POST /api/logs
2. NATS Event Bus: infortts.logs.> from infortts-nats-shared:4222
3. LLM Diagnostic Engine: POST /api/v1/observability/diagnose (connects to infortts-ollama)
"""

from __future__ import annotations

import os
import sys
import json
import time
import uuid
import logging
import asyncio
import datetime
import urllib.request
import urllib.error
from typing import List, Optional, Dict, Any, Union

try:
    from fastapi import FastAPI, Request, BackgroundTasks, Query, HTTPException, status
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse
    from pydantic import BaseModel, Field
    import uvicorn
    HAS_FASTAPI = True
except ImportError:
    HAS_FASTAPI = False

# Configuration
PORT = int(os.getenv("OBSERVABILITY_PORT", os.getenv("LOG_SERVER_PORT", "8091")))
POSTGRES_URL = os.getenv("POSTGRES_URL", "postgresql://infortts_admin:InforttsSecureDB2026!@infortts-postgres-shared:5432/mitochondria_db")
NATS_URL = os.getenv("NATS_URL", "nats://infortts-nats-shared:4222")
OLLAMA_URL = os.getenv("OLLAMA_BASE_URL", "http://infortts-ollama:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5-coder:3b")
_shared_dir = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SQLITE_PATH = os.path.join(_shared_dir, "cache", "observability.db")
SQLITE_FALLBACK_PATH = os.getenv("OBSERVABILITY_SQLITE_PATH", DEFAULT_SQLITE_PATH)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("infortts-observability")

# --- Storage Engine (Postgres + SQLite Fallback) ----------------------------

class LogStorage:
    def __init__(self):
        self.use_postgres = False
        self.pg_conn = None
        self._init_db()

    def _init_db(self):
        try:
            import psycopg2
            import psycopg2.extras
            # Test postgres connection
            conn = psycopg2.connect(POSTGRES_URL, connect_timeout=3)
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute("""
                CREATE TABLE IF NOT EXISTS system_logs (
                    id TEXT PRIMARY KEY,
                    timestamp TIMESTAMPTZ NOT NULL,
                    app TEXT NOT NULL DEFAULT 'unknown',
                    service TEXT NOT NULL DEFAULT 'general',
                    level TEXT NOT NULL DEFAULT 'INFO',
                    message TEXT NOT NULL,
                    context JSONB NOT NULL DEFAULT '{}'::jsonb,
                    trace_id TEXT,
                    stack_trace TEXT,
                    host TEXT DEFAULT ''
                );
                CREATE INDEX IF NOT EXISTS idx_logs_app_level_ts ON system_logs(app, level, timestamp DESC);
                CREATE INDEX IF NOT EXISTS idx_logs_ts ON system_logs(timestamp DESC);
                CREATE INDEX IF NOT EXISTS idx_logs_trace ON system_logs(trace_id) WHERE trace_id IS NOT NULL;
                """)
            conn.close()
            self.use_postgres = True
            logger.info("Connected to PostgreSQL for observability storage")
        except Exception as exc:
            logger.warning("PostgreSQL unavailable (%s), using SQLite fallback at %s", exc, SQLITE_FALLBACK_PATH)
            self.use_postgres = False
            self._init_sqlite()

    def _init_sqlite(self):
        import sqlite3
        global SQLITE_FALLBACK_PATH
        try:
            os.makedirs(os.path.dirname(os.path.abspath(SQLITE_FALLBACK_PATH)), exist_ok=True)
        except OSError:
            SQLITE_FALLBACK_PATH = "/tmp/infortts_observability.db"
        conn = sqlite3.connect(SQLITE_FALLBACK_PATH, timeout=10)
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("""
        CREATE TABLE IF NOT EXISTS system_logs (
            id TEXT PRIMARY KEY,
            timestamp TEXT NOT NULL,
            app TEXT NOT NULL DEFAULT 'unknown',
            service TEXT NOT NULL DEFAULT 'general',
            level TEXT NOT NULL DEFAULT 'INFO',
            message TEXT NOT NULL,
            context TEXT NOT NULL DEFAULT '{}',
            trace_id TEXT,
            stack_trace TEXT,
            host TEXT DEFAULT ''
        );
        """)
        conn.execute("CREATE INDEX IF NOT EXISTS idx_sq_logs_app ON system_logs(app, level, timestamp DESC)")
        conn.execute("CREATE INDEX IF NOT EXISTS idx_sq_logs_ts ON system_logs(timestamp DESC)")
        conn.close()

    def insert_logs(self, logs: List[Dict[str, Any]]) -> int:
        if not logs:
            return 0
        if self.use_postgres:
            return self._insert_pg(logs)
        return self._insert_sqlite(logs)

    def _insert_pg(self, logs: List[Dict[str, Any]]) -> int:
        import psycopg2
        import psycopg2.extras
        inserted = 0
        try:
            conn = psycopg2.connect(POSTGRES_URL, connect_timeout=3)
            conn.autocommit = True
            with conn.cursor() as cur:
                for item in logs:
                    log_id = str(item.get("id") or f"log_{uuid.uuid4().hex[:16]}")
                    ts = item.get("timestamp") or datetime.datetime.now(datetime.timezone.utc).isoformat()
                    app = str(item.get("app") or item.get("app_name") or "unknown")
                    service = str(item.get("service") or "general")
                    level = str(item.get("level") or "INFO").upper()
                    msg = str(item.get("message") or "")
                    ctx = item.get("context") or item.get("metadata") or {}
                    trace_id = item.get("trace_id")
                    stack = item.get("stack_trace")
                    host = str(item.get("host") or item.get("environment") or "")

                    cur.execute(
                        """
                        INSERT INTO system_logs (id, timestamp, app, service, level, message, context, trace_id, stack_trace, host)
                        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
                        ON CONFLICT (id) DO NOTHING
                        """,
                        (log_id, ts, app, service, level, msg, json.dumps(ctx), trace_id, stack, host)
                    )
                    inserted += 1
            conn.close()
        except Exception as exc:
            logger.error("Postgres insert failed: %s, falling back to SQLite", exc)
            return self._insert_sqlite(logs)
        return inserted

    def _insert_sqlite(self, logs: List[Dict[str, Any]]) -> int:
        import sqlite3
        inserted = 0
        try:
            conn = sqlite3.connect(SQLITE_FALLBACK_PATH, timeout=10)
            for item in logs:
                log_id = str(item.get("id") or f"log_{uuid.uuid4().hex[:16]}")
                ts = item.get("timestamp") or datetime.datetime.now(datetime.timezone.utc).isoformat()
                app = str(item.get("app") or item.get("app_name") or "unknown")
                service = str(item.get("service") or "general")
                level = str(item.get("level") or "INFO").upper()
                msg = str(item.get("message") or "")
                ctx = item.get("context") or item.get("metadata") or {}
                trace_id = item.get("trace_id")
                stack = item.get("stack_trace")
                host = str(item.get("host") or item.get("environment") or "")

                conn.execute(
                    """
                    INSERT OR IGNORE INTO system_logs (id, timestamp, app, service, level, message, context, trace_id, stack_trace, host)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
                    """,
                    (log_id, str(ts), app, service, level, msg, json.dumps(ctx), trace_id, stack, host)
                )
                inserted += 1
            conn.commit()
            conn.close()
        except Exception as exc:
            logger.error("SQLite insert failed: %s", exc)
        return inserted

    def query_logs(
        self,
        app: Optional[str] = None,
        service: Optional[str] = None,
        level: Optional[str] = None,
        search: Optional[str] = None,
        trace_id: Optional[str] = None,
        since_minutes: Optional[int] = None,
        limit: int = 100,
        offset: int = 0
    ) -> List[Dict[str, Any]]:
        if self.use_postgres:
            return self._query_pg(app, service, level, search, trace_id, since_minutes, limit, offset)
        return self._query_sqlite(app, service, level, search, trace_id, since_minutes, limit, offset)

    def _query_pg(self, app, service, level, search, trace_id, since_minutes, limit, offset):
        import psycopg2
        import psycopg2.extras
        conditions = ["1=1"]
        params = []

        if app:
            conditions.append("app = %s")
            params.append(app)
        if service:
            conditions.append("service = %s")
            params.append(service)
        if level:
            conditions.append("level = %s")
            params.append(level.upper())
        if trace_id:
            conditions.append("trace_id = %s")
            params.append(trace_id)
        if search:
            conditions.append("(message ILIKE %s OR stack_trace ILIKE %s)")
            params.extend([f"%{search}%", f"%{search}%"])
        if since_minutes and since_minutes > 0:
            conditions.append("timestamp >= NOW() - make_interval(mins => %s)")
            params.append(since_minutes)

        params.extend([limit, offset])
        sql = f"""
        SELECT id, timestamp, app, service, level, message, context, trace_id, stack_trace, host
        FROM system_logs
        WHERE {' AND '.join(conditions)}
        ORDER BY timestamp DESC
        LIMIT %s OFFSET %s
        """
        results = []
        try:
            conn = psycopg2.connect(POSTGRES_URL, connect_timeout=3)
            with conn.cursor(cursor_factory=psycopg2.extras.DictCursor) as cur:
                cur.execute(sql, params)
                for row in cur.fetchall():
                    results.append({
                        "id": row["id"],
                        "timestamp": row["timestamp"].isoformat() if hasattr(row["timestamp"], "isoformat") else str(row["timestamp"]),
                        "app": row["app"],
                        "service": row["service"],
                        "level": row["level"],
                        "message": row["message"],
                        "context": row["context"] if isinstance(row["context"], dict) else json.loads(row["context"] or "{}"),
                        "trace_id": row["trace_id"],
                        "stack_trace": row["stack_trace"],
                        "host": row["host"]
                    })
            conn.close()
        except Exception as exc:
            logger.error("Postgres query failed: %s", exc)
            return self._query_sqlite(app, service, level, search, trace_id, since_minutes, limit, offset)
        return results

    def _query_sqlite(self, app, service, level, search, trace_id, since_minutes, limit, offset):
        import sqlite3
        conditions = ["1=1"]
        params = []

        if app:
            conditions.append("app = ?")
            params.append(app)
        if service:
            conditions.append("service = ?")
            params.append(service)
        if level:
            conditions.append("level = ?")
            params.append(level.upper())
        if trace_id:
            conditions.append("trace_id = ?")
            params.append(trace_id)
        if search:
            conditions.append("(message LIKE ? OR stack_trace LIKE ?)")
            params.extend([f"%{search}%", f"%{search}%"])
        if since_minutes and since_minutes > 0:
            cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(minutes=since_minutes)).isoformat()
            conditions.append("timestamp >= ?")
            params.append(cutoff)

        params.extend([limit, offset])
        sql = f"""
        SELECT id, timestamp, app, service, level, message, context, trace_id, stack_trace, host
        FROM system_logs
        WHERE {' AND '.join(conditions)}
        ORDER BY timestamp DESC
        LIMIT ? OFFSET ?
        """
        results = []
        try:
            conn = sqlite3.connect(SQLITE_FALLBACK_PATH, timeout=10)
            conn.row_factory = sqlite3.Row
            rows = conn.execute(sql, params).fetchall()
            for r in rows:
                results.append({
                    "id": r["id"],
                    "timestamp": r["timestamp"],
                    "app": r["app"],
                    "service": r["service"],
                    "level": r["level"],
                    "message": r["message"],
                    "context": json.loads(r["context"] or "{}") if isinstance(r["context"], str) else (r["context"] or {}),
                    "trace_id": r["trace_id"],
                    "stack_trace": r["stack_trace"],
                    "host": r["host"]
                })
            conn.close()
        except Exception as exc:
            logger.error("SQLite query failed: %s", exc)
        return results

    def get_stats(self, hours: int = 24) -> Dict[str, Any]:
        if self.use_postgres:
            return self._get_stats_pg(hours)
        return self._get_stats_sqlite(hours)

    def _get_stats_pg(self, hours: int) -> Dict[str, Any]:
        import psycopg2
        stats = {
            "time_window_hours": hours,
            "total_logs": 0,
            "by_level": {},
            "by_app": {},
            "error_rate": 0.0,
            "top_errors": []
        }
        try:
            conn = psycopg2.connect(POSTGRES_URL, connect_timeout=3)
            with conn.cursor() as cur:
                # Level breakdown
                cur.execute(
                    "SELECT level, COUNT(*) FROM system_logs WHERE timestamp >= NOW() - make_interval(hours => %s) GROUP BY level",
                    (hours,)
                )
                for lvl, cnt in cur.fetchall():
                    stats["by_level"][lvl] = cnt
                    stats["total_logs"] += cnt

                # App breakdown
                cur.execute(
                    "SELECT app, COUNT(*) FROM system_logs WHERE timestamp >= NOW() - make_interval(hours => %s) GROUP BY app ORDER BY COUNT(*) DESC",
                    (hours,)
                )
                for app_name, cnt in cur.fetchall():
                    stats["by_app"][app_name] = cnt

                # Top error messages
                cur.execute(
                    """
                    SELECT message, COUNT(*) as c
                    FROM system_logs
                    WHERE level IN ('ERROR', 'CRITICAL') AND timestamp >= NOW() - make_interval(hours => %s)
                    GROUP BY message
                    ORDER BY c DESC LIMIT 5
                    """,
                    (hours,)
                )
                for msg, cnt in cur.fetchall():
                    stats["top_errors"].append({"message": msg, "count": cnt})

            conn.close()
            error_count = stats["by_level"].get("ERROR", 0) + stats["by_level"].get("CRITICAL", 0)
            if stats["total_logs"] > 0:
                stats["error_rate"] = round((error_count / stats["total_logs"]) * 100, 2)
        except Exception as exc:
            logger.error("Postgres stats failed: %s", exc)
            return self._get_stats_sqlite(hours)
        return stats

    def _get_stats_sqlite(self, hours: int) -> Dict[str, Any]:
        import sqlite3
        cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(hours=hours)).isoformat()
        stats = {
            "time_window_hours": hours,
            "total_logs": 0,
            "by_level": {},
            "by_app": {},
            "error_rate": 0.0,
            "top_errors": []
        }
        try:
            conn = sqlite3.connect(SQLITE_FALLBACK_PATH, timeout=10)
            rows = conn.execute(
                "SELECT level, COUNT(*) FROM system_logs WHERE timestamp >= ? GROUP BY level",
                (cutoff,)
            ).fetchall()
            for lvl, cnt in rows:
                stats["by_level"][lvl] = cnt
                stats["total_logs"] += cnt

            app_rows = conn.execute(
                "SELECT app, COUNT(*) FROM system_logs WHERE timestamp >= ? GROUP BY app ORDER BY COUNT(*) DESC",
                (cutoff,)
            ).fetchall()
            for app_name, cnt in app_rows:
                stats["by_app"][app_name] = cnt

            err_rows = conn.execute(
                "SELECT message, COUNT(*) as c FROM system_logs WHERE level IN ('ERROR', 'CRITICAL') AND timestamp >= ? GROUP BY message ORDER BY c DESC LIMIT 5",
                (cutoff,)
            ).fetchall()
            for msg, cnt in err_rows:
                stats["top_errors"].append({"message": msg, "count": cnt})

            conn.close()
            error_count = stats["by_level"].get("ERROR", 0) + stats["by_level"].get("CRITICAL", 0)
            if stats["total_logs"] > 0:
                stats["error_rate"] = round((error_count / stats["total_logs"]) * 100, 2)
        except Exception as exc:
            logger.error("SQLite stats failed: %s", exc)
        return stats

    def prune_old_logs(self, info_retention_days: int = 14, error_retention_days: int = 30) -> int:
        if self.use_postgres:
            return self._prune_pg(info_retention_days, error_retention_days)
        return self._prune_sqlite(info_retention_days, error_retention_days)

    def _prune_pg(self, info_days: int, error_days: int) -> int:
        import psycopg2
        deleted = 0
        try:
            conn = psycopg2.connect(POSTGRES_URL, connect_timeout=3)
            conn.autocommit = True
            with conn.cursor() as cur:
                cur.execute(
                    "DELETE FROM system_logs WHERE level IN ('DEBUG', 'INFO', 'WARNING') AND timestamp < NOW() - make_interval(days => %s)",
                    (info_days,)
                )
                deleted += cur.rowcount
                cur.execute(
                    "DELETE FROM system_logs WHERE level IN ('ERROR', 'CRITICAL') AND timestamp < NOW() - make_interval(days => %s)",
                    (error_days,)
                )
                deleted += cur.rowcount
            conn.close()
        except Exception as exc:
            logger.error("Postgres prune failed: %s", exc)
        return deleted

    def _prune_sqlite(self, info_days: int, error_days: int) -> int:
        import sqlite3
        deleted = 0
        info_cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=info_days)).isoformat()
        err_cutoff = (datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=error_days)).isoformat()
        try:
            conn = sqlite3.connect(SQLITE_FALLBACK_PATH, timeout=10)
            c1 = conn.execute(
                "DELETE FROM system_logs WHERE level IN ('DEBUG', 'INFO', 'WARNING') AND timestamp < ?",
                (info_cutoff,)
            )
            deleted += c1.rowcount
            c2 = conn.execute(
                "DELETE FROM system_logs WHERE level IN ('ERROR', 'CRITICAL') AND timestamp < ?",
                (err_cutoff,)
            )
            deleted += c2.rowcount
            conn.commit()
            conn.close()
        except Exception as exc:
            logger.error("SQLite prune failed: %s", exc)
        return deleted

storage = LogStorage()

# --- LLM Diagnostic Service (Ollama Engine) --------------------------------

def diagnose_logs_with_llm(
    logs: List[Dict[str, Any]],
    user_query: str = "Analyze the recent error patterns, find the root cause, and provide fix recommendations."
) -> Dict[str, Any]:
    """Sends log anomalies to local Ollama (qwen2.5-coder:3b) for zero-cost diagnosis."""
    if not logs:
        return {
            "status": "clean",
            "summary": "No matching errors or anomalies found in the requested time window.",
            "root_cause_analysis": "All tracked services are running smoothly.",
            "recommended_actions": ["Continue standard monitoring"],
            "model_used": "rule_based",
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }

    # Format logs for LLM
    log_snippets = []
    for l in logs[:15]:  # limit to top 15 most relevant logs
        snippet = f"[{l.get('timestamp')}] {l.get('app')}/{l.get('service')} {l.get('level')}: {l.get('message')}"
        if l.get('stack_trace'):
            st = l.get('stack_trace', '')
            lines = st.strip().split('\n')
            short_st = '\n'.join(lines[-4:]) if len(lines) > 4 else st
            snippet += f"\nStack: {short_st}"
        log_snippets.append(snippet)

    joined_logs = "\n---\n".join(log_snippets)
    prompt = f"""You are the Infortts Autonomous Observability Diagnostic Agent.
Analyze these system logs from our production services and provide a concise diagnosis.

USER QUERY: {user_query}

LOG DATA:
{joined_logs}

Please respond with a structured diagnosis containing:
1. Root Cause Summary (1-2 sentences explaining what failed)
2. Affected Components
3. Recommended Fix Action (step-by-step technical fix)
Keep the answer direct, precise, and without conversational filler."""

    try:
        req_data = json.dumps({
            "model": OLLAMA_MODEL,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.2,
                "num_predict": 400
            }
        }).encode("utf-8")

        req = urllib.request.Request(
            f"{OLLAMA_URL}/api/generate",
            data=req_data,
            headers={"Content-Type": "application/json"},
            method="POST"
        )
        with urllib.request.urlopen(req, timeout=12) as resp:
            data = json.loads(resp.read().decode("utf-8"))
            llm_text = data.get("response", "").strip()

            return {
                "status": "analyzed",
                "summary": "LLM Root Cause Diagnosis Completed",
                "diagnosis": llm_text,
                "model_used": OLLAMA_MODEL,
                "analyzed_logs_count": len(logs),
                "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
            }
    except Exception as exc:
        logger.warning("Ollama diagnosis unavailable (%s) — using heuristic analysis", exc)
        # Heuristic rule-based fallback
        top_errors = {}
        for l in logs:
            msg = l.get("message", "Unknown error")
            top_errors[msg] = top_errors.get(msg, 0) + 1
        sorted_errors = sorted(top_errors.items(), key=lambda x: x[1], reverse=True)

        return {
            "status": "analyzed_heuristic",
            "summary": f"Detected {len(logs)} error/warning logs across services.",
            "diagnosis": f"Primary error cluster: {sorted_errors[0][0] if sorted_errors else 'None'}",
            "error_clusters": [{"message": k, "occurrences": v} for k, v in sorted_errors[:5]],
            "recommended_actions": [
                "Check network connectivity to dependent services",
                "Inspect database connection pool limits",
                "Review recent branch deployments"
            ],
            "model_used": "heuristic_fallback",
            "analyzed_logs_count": len(logs),
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }

# --- Background NATS Listener -----------------------------------------------

async def start_nats_log_consumer():
    """Subscribes to infortts.logs.> topic to ingest logs published via NATS."""
    try:
        import nats
        nc = await nats.connect(NATS_URL, connect_timeout=3)
        logger.info("Observability NATS consumer connected to %s", NATS_URL)

        async def log_handler(msg):
            try:
                data = json.loads(msg.data.decode("utf-8"))
                if isinstance(data, list):
                    storage.insert_logs(data)
                elif isinstance(data, dict):
                    storage.insert_logs([data])
            except Exception as e:
                logger.debug("Failed to parse NATS log message: %s", e)

        await nc.subscribe("infortts.logs.>", cb=log_handler)
    except Exception as exc:
        logger.warning("NATS log subscriber disabled (%s)", exc)

# --- FastAPI Application ---------------------------------------------------

if HAS_FASTAPI:
    app = FastAPI(
        title="Infortts Central Observability & LLM Log Server",
        description="Centralized log ingestion, filtering, and LLM-powered root-cause diagnosis.",
        version="2.0.0"
    )

    app.add_middleware(
        CORSMiddleware,
        allow_origins=["*"],
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    class LogEntry(BaseModel):
        id: Optional[str] = None
        timestamp: Optional[str] = None
        app: str = "unknown"
        service: str = "general"
        level: str = "INFO"
        message: str
        context: Optional[Dict[str, Any]] = None
        trace_id: Optional[str] = None
        stack_trace: Optional[str] = None
        host: Optional[str] = None

    class IngestRequest(BaseModel):
        logs: Union[List[LogEntry], LogEntry]

    class DiagnoseRequest(BaseModel):
        app: Optional[str] = None
        service: Optional[str] = None
        query: str = "Explain root cause of recent errors and recommend fixes."
        time_window_minutes: int = 60
        limit: int = 25

    @app.on_event("startup")
    async def startup_event():
        asyncio.create_task(start_nats_log_consumer())

    @app.get("/health")
    @app.get("/api/v1/observability/health")
    def health():
        return {
            "status": "healthy",
            "service": "infortts-observability",
            "storage_mode": "postgres" if storage.use_postgres else "sqlite",
            "ollama_model": OLLAMA_MODEL,
            "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat()
        }

    @app.post("/api/v1/logs/ingest")
    @app.post("/api/logs")
    async def ingest_logs(request: Request, background_tasks: BackgroundTasks):
        try:
            body = await request.json()
            if isinstance(body, list):
                logs_list = body
            elif isinstance(body, dict):
                if "logs" in body:
                    logs_list = body["logs"] if isinstance(body["logs"], list) else [body["logs"]]
                else:
                    logs_list = [body]
            else:
                raise HTTPException(status_code=400, detail="Invalid log payload")

            inserted = storage.insert_logs(logs_list)
            return {"status": "ok", "inserted": inserted}
        except Exception as exc:
            raise HTTPException(status_code=400, detail=str(exc))

    @app.get("/api/v1/logs/query")
    def query_logs(
        app: Optional[str] = None,
        service: Optional[str] = None,
        level: Optional[str] = None,
        search: Optional[str] = None,
        trace_id: Optional[str] = None,
        since_minutes: Optional[int] = Query(default=60),
        limit: int = Query(default=100, le=500),
        offset: int = Query(default=0)
    ):
        results = storage.query_logs(
            app=app,
            service=service,
            level=level,
            search=search,
            trace_id=trace_id,
            since_minutes=since_minutes,
            limit=limit,
            offset=offset
        )
        return {
            "status": "ok",
            "count": len(results),
            "logs": results
        }

    @app.get("/api/v1/logs/stats")
    def get_stats(hours: int = Query(default=24, le=168)):
        stats = storage.get_stats(hours=hours)
        return {"status": "ok", "stats": stats}

    @app.get("/api/v1/logs/errors")
    def get_errors(
        app: Optional[str] = None,
        since_minutes: int = Query(default=120),
        limit: int = Query(default=50, le=200)
    ):
        errors = storage.query_logs(
            app=app,
            level="ERROR",
            since_minutes=since_minutes,
            limit=limit
        )
        return {"status": "ok", "count": len(errors), "errors": errors}

    @app.post("/api/v1/observability/diagnose")
    def diagnose_system(req: DiagnoseRequest):
        # Fetch relevant errors and warnings
        error_logs = storage.query_logs(
            app=req.app,
            service=req.service,
            level="ERROR",
            since_minutes=req.time_window_minutes,
            limit=req.limit
        )
        if not error_logs:
            error_logs = storage.query_logs(
                app=req.app,
                service=req.service,
                level="WARNING",
                since_minutes=req.time_window_minutes,
                limit=req.limit
            )

        diagnosis = diagnose_logs_with_llm(error_logs, user_query=req.query)
        return diagnosis

    @app.post("/api/v1/logs/prune")
    def prune_logs(info_days: int = Query(default=14), error_days: int = Query(default=30)):
        deleted = storage.prune_old_logs(info_retention_days=info_days, error_retention_days=error_days)
        return {"status": "ok", "deleted_records": deleted}

# --- CLI Entry Point --------------------------------------------------------

if __name__ == "__main__":
    if not HAS_FASTAPI:
        print("FastAPI / uvicorn not installed locally. Use standalone ingestion or run under virtualenv.")
        sys.exit(1)
    uvicorn.run(app, host="0.0.0.0", port=PORT, log_level="info")
