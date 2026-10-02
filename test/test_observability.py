#!/usr/bin/env python3
"""
Unit tests for Infortts Observability Server and Logger
"""

import os
import sys
import time
import uuid
import unittest
import tempfile
import logging

_here = os.path.dirname(os.path.abspath(__file__))
_parent = os.path.dirname(_here)
if _parent not in sys.path:
    sys.path.insert(0, _parent)

import infortts_observability_server as obs
import infortts_logger


class TestObservabilityStorage(unittest.TestCase):
    def setUp(self):
        self.tmp_dir = tempfile.TemporaryDirectory()
        self.db_path = os.path.join(self.tmp_dir.name, "test_obs.db")
        obs.SQLITE_FALLBACK_PATH = self.db_path
        self.storage = obs.LogStorage()
        self.storage.use_postgres = False
        self.storage._init_sqlite()

    def tearDown(self):
        self.tmp_dir.cleanup()

    def test_insert_and_query_logs(self):
        logs = [
            {
                "id": "log_1",
                "app": "mitochondria",
                "service": "mt5_bridge",
                "level": "INFO",
                "message": "Bridge connected to XM account 318628196",
                "context": {"login": 318628196},
                "host": "node-1"
            },
            {
                "id": "log_2",
                "app": "glycocalyx",
                "service": "auth_server",
                "level": "ERROR",
                "message": "Database pool exhausted on webauthn ceremony",
                "context": {"error": "pool_timeout"},
                "stack_trace": "Traceback (most recent call last):\n  File 'main.go': line 45",
                "host": "node-1"
            }
        ]

        inserted = self.storage.insert_logs(logs)
        self.assertEqual(inserted, 2)

        # Query all logs
        all_logs = self.storage.query_logs(limit=10)
        self.assertEqual(len(all_logs), 2)

        # Filter by app
        mito_logs = self.storage.query_logs(app="mitochondria")
        self.assertEqual(len(mito_logs), 1)
        self.assertEqual(mito_logs[0]["service"], "mt5_bridge")

        # Filter by level
        error_logs = self.storage.query_logs(level="ERROR")
        self.assertEqual(len(error_logs), 1)
        self.assertEqual(error_logs[0]["app"], "glycocalyx")

        # Search text
        search_logs = self.storage.query_logs(search="pool exhausted")
        self.assertEqual(len(search_logs), 1)

    def test_get_stats(self):
        logs = [
            {"id": f"log_{i}", "app": "mitochondria", "level": "INFO", "message": f"msg {i}"}
            for i in range(8)
        ]
        logs.extend([
            {"id": f"err_{i}", "app": "mitochondria", "level": "ERROR", "message": "Failed order gate"}
            for i in range(2)
        ])
        self.storage.insert_logs(logs)

        stats = self.storage.get_stats(hours=1)
        self.assertEqual(stats["total_logs"], 10)
        self.assertEqual(stats["by_level"]["INFO"], 8)
        self.assertEqual(stats["by_level"]["ERROR"], 2)
        self.assertEqual(stats["error_rate"], 20.0)
        self.assertEqual(len(stats["top_errors"]), 1)
        self.assertEqual(stats["top_errors"][0]["count"], 2)

    def test_diagnose_heuristic_fallback(self):
        error_logs = [
            {
                "app": "mitochondria",
                "service": "single_executor",
                "level": "ERROR",
                "message": "sqlite3.OperationalError: cannot rollback - no transaction is active",
                "stack_trace": "Traceback:\n  File order_outbox.py line 464"
            }
        ]

        diagnosis = obs.diagnose_logs_with_llm(error_logs, user_query="Why did outbox fail?")
        self.assertIn("status", diagnosis)
        self.assertIn("diagnosis", diagnosis)
        self.assertEqual(diagnosis["analyzed_logs_count"], 1)

    def test_prune_logs(self):
        old_ts = (obs.datetime.datetime.now(obs.datetime.timezone.utc) - obs.datetime.timedelta(days=40)).isoformat()
        logs = [
            {"id": "old_info", "timestamp": old_ts, "app": "test", "level": "INFO", "message": "old"},
            {"id": "old_err", "timestamp": old_ts, "app": "test", "level": "ERROR", "message": "old err"},
            {"id": "new_info", "app": "test", "level": "INFO", "message": "recent"}
        ]
        self.storage.insert_logs(logs)

        deleted = self.storage.prune_old_logs(info_retention_days=14, error_retention_days=30)
        self.assertEqual(deleted, 2)

        remaining = self.storage.query_logs()
        self.assertEqual(len(remaining), 1)
        self.assertEqual(remaining[0]["id"], "new_info")


if __name__ == "__main__":
    unittest.main()
