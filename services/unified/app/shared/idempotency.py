from __future__ import annotations

from uuid import uuid4


def new_idempotency_key() -> str:
    return str(uuid4())
