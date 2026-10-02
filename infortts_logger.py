#!/usr/bin/env python3
"""
Infortts Unified Observability Logger & Log Shipper
Non-blocking, high-throughput structured JSON logging handler for Python microservices.
Dispatches logs asynchronously to the central Observability Log Server (port 8091).
"""

from __future__ import annotations

import os
import sys
import json
import queue
import logging
import threading
import datetime
import urllib.request
import urllib.error
from typing import Optional, Dict, Any

DEFAULT_SERVER_URL = os.getenv("OBSERVABILITY_URL", "http://127.0.0.1:8091")

class InforttsLogHandler(logging.Handler):
    """
    Asynchronous logging handler that buffers log records and dispatches them in
    batches via HTTP to the central Infortts Log Server without blocking application threads.
    """

    def __init__(
        self,
        app_name: str,
        service_name: str = "general",
        server_url: str = DEFAULT_SERVER_URL,
        batch_size: int = 20,
        flush_interval_s: float = 2.0,
        level: int = logging.INFO
    ):
        super().__init__(level=level)
        self.app_name = app_name
        self.service_name = service_name
        self.server_url = server_url.rstrip("/")
        self.batch_size = batch_size
        self.flush_interval_s = flush_interval_s

        self.queue: queue.Queue = queue.Queue(maxsize=5000)
        self.running = True
        self.worker = threading.Thread(target=self._worker_loop, daemon=True, name="InforttsLogShipper")
        self.worker.start()

    def emit(self, record: logging.LogRecord):
        try:
            entry = {
                "timestamp": datetime.datetime.now(datetime.timezone.utc).isoformat(),
                "app": self.app_name,
                "service": self.service_name,
                "level": record.levelname,
                "message": self.format(record) if self.formatter else record.getMessage(),
                "trace_id": getattr(record, "trace_id", None),
                "context": getattr(record, "context", {}),
                "host": os.getenv("HOSTNAME", "node")
            }

            if record.exc_info:
                import traceback
                entry["stack_trace"] = "".join(traceback.format_exception(*record.exc_info))

            try:
                self.queue.put_nowait(entry)
            except queue.Full:
                pass  # Drop under extreme backpressure rather than blocking main thread
        except Exception:
            self.handleError(record)

    def _worker_loop(self):
        while self.running:
            batch = []
            start = time.time()

            while len(batch) < self.batch_size and (time.time() - start) < self.flush_interval_s:
                try:
                    timeout = max(0.1, self.flush_interval_s - (time.time() - start))
                    item = self.queue.get(timeout=timeout)
                    batch.append(item)
                    self.queue.task_done()
                except queue.Empty:
                    break

            if batch:
                self._send_batch(batch)

    def _send_batch(self, batch: list):
        endpoint = f"{self.server_url}/api/v1/logs/ingest"
        try:
            data = json.dumps(batch).encode("utf-8")
            req = urllib.request.Request(
                endpoint,
                data=data,
                headers={"Content-Type": "application/json"},
                method="POST"
            )
            with urllib.request.urlopen(req, timeout=3) as resp:
                pass
        except Exception:
            # Silent failure to ensure logging shipper never brings down host process
            pass

    def close(self):
        self.running = False
        super().close()


def get_infortts_logger(
    app_name: str,
    service_name: str = "general",
    level: int = logging.INFO
) -> logging.Logger:
    """Configures and returns a standard Python logger with the InforttsLogHandler attached."""
    logger_instance = logging.getLogger(f"infortts.{app_name}.{service_name}")
    logger_instance.setLevel(level)

    # Add console stream handler if not already present
    if not any(isinstance(h, logging.StreamHandler) for h in logger_instance.handlers):
        sh = logging.StreamHandler(sys.stdout)
        sh.setFormatter(logging.Formatter("%(asctime)s [%(levelname)s] %(name)s: %(message)s"))
        logger_instance.addHandler(sh)

    # Add InforttsLogHandler
    handler = InforttsLogHandler(app_name=app_name, service_name=service_name, level=level)
    logger_instance.addHandler(handler)

    return logger_instance
