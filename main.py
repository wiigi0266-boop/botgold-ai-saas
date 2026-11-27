"""
BotGold AI — Backend minimal (FastAPI)
Historise les décisions SKIP / TRADE du dashboard et de l'EA.
"""

from datetime import datetime, timezone
from typing import Optional, List
from enum import Enum

from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
import sqlite3
import os

DB_PATH = os.environ.get("BOTGOLD_DB", "botgold.db")

app = FastAPI(
    title="BotGold AI API",
    description="Historique des décisions anti-martingale (SKIP / TRADE)",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class Action(str, Enum):
    SKIP = "SKIP"
    TRADE = "TRADE"


class DecisionIn(BaseModel):
    action: Action
    direction: Optional[str] = None  # BUY | SELL | null
    symbol: str = "XAUUSD"
    price: Optional[float] = None
    score: Optional[int] = None
    context_strength: Optional[float] = None
    fg_score: Optional[int] = None
    rsi: Optional[float] = None
    reason: str = ""
    rule_hit: Optional[str] = None
    lot_size: Optional[float] = None
    risk_percent: Optional[float] = None
    source: str = "dashboard"  # dashboard | ea | api


class DecisionOut(DecisionIn):
    id: int
    created_at: str


def get_db():
    conn = sqlite3.connect(DB_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def init_db():
    conn = get_db()
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS decisions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            action TEXT NOT NULL,
            direction TEXT,
            symbol TEXT DEFAULT 'XAUUSD',
            price REAL,
            score INTEGER,
            context_strength REAL,
            fg_score INTEGER,
            rsi REAL,
            reason TEXT,
            rule_hit TEXT,
            lot_size REAL,
            risk_percent REAL,
            source TEXT DEFAULT 'dashboard',
            created_at TEXT NOT NULL
        )
        """
    )
    conn.commit()
    conn.close()


@app.on_event("startup")
def startup():
    init_db()


@app.get("/")
def root():
    return {
        "service": "BotGold AI API",
        "version": "0.1.0",
        "endpoints": ["/health", "/decisions", "/stats"],
    }


@app.get("/health")
def health():
    return {"status": "ok", "ts": datetime.now(timezone.utc).isoformat()}


@app.post("/decisions", response_model=DecisionOut)
def create_decision(body: DecisionIn):
    now = datetime.now(timezone.utc).isoformat()
    conn = get_db()
    cur = conn.execute(
        """
        INSERT INTO decisions
        (action, direction, symbol, price, score, context_strength, fg_score, rsi,
         reason, rule_hit, lot_size, risk_percent, source, created_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            body.action.value,
            body.direction,
            body.symbol,
            body.price,
            body.score,
            body.context_strength,
            body.fg_score,
            body.rsi,
            body.reason,
            body.rule_hit,
            body.lot_size,
            body.risk_percent,
            body.source,
            now,
        ),
    )
    conn.commit()
    row_id = cur.lastrowid
    conn.close()
    return DecisionOut(id=row_id, created_at=now, **body.model_dump())


@app.get("/decisions", response_model=List[DecisionOut])
def list_decisions(
    limit: int = Query(50, ge=1, le=500),
    action: Optional[Action] = None,
    source: Optional[str] = None,
):
    conn = get_db()
    sql = "SELECT * FROM decisions WHERE 1=1"
    params = []
    if action:
        sql += " AND action = ?"
        params.append(action.value)
    if source:
        sql += " AND source = ?"
        params.append(source)
    sql += " ORDER BY id DESC LIMIT ?"
    params.append(limit)
    rows = conn.execute(sql, params).fetchall()
    conn.close()
    return [
        DecisionOut(
            id=r["id"],
            action=r["action"],
            direction=r["direction"],
            symbol=r["symbol"],
            price=r["price"],
            score=r["score"],
            context_strength=r["context_strength"],
            fg_score=r["fg_score"],
            rsi=r["rsi"],
            reason=r["reason"] or "",
            rule_hit=r["rule_hit"],
            lot_size=r["lot_size"],
            risk_percent=r["risk_percent"],
            source=r["source"],
            created_at=r["created_at"],
        )
        for r in rows
    ]


@app.get("/stats")
def stats():
    conn = get_db()
    total = conn.execute("SELECT COUNT(*) AS c FROM decisions").fetchone()["c"]
    skips = conn.execute(
        "SELECT COUNT(*) AS c FROM decisions WHERE action = 'SKIP'"
    ).fetchone()["c"]
    trades = conn.execute(
        "SELECT COUNT(*) AS c FROM decisions WHERE action = 'TRADE'"
    ).fetchone()["c"]
    last = conn.execute(
        "SELECT created_at FROM decisions ORDER BY id DESC LIMIT 1"
    ).fetchone()
    conn.close()
    return {
        "total": total,
        "skips": skips,
        "trades": trades,
        "skip_ratio": round(skips / total, 3) if total else 0,
        "last_decision_at": last["created_at"] if last else None,
    }




class PositionIn(BaseModel):
    ticket: int
    symbol: str = "GOLD"
    type: str  # BUY | SELL
    volume: float
    price_open: float
    sl: Optional[float] = None
    tp: Optional[float] = None
    profit: Optional[float] = None
    magic: Optional[int] = None

class AccountIn(BaseModel):
    balance: float
    equity: float
    margin: Optional[float] = None
    free_margin: Optional[float] = None
    currency: str = "USD"

# In-memory store for latest positions and account (simple)
latest_positions = []
latest_account = None

@app.post("/positions")
def update_positions(positions: List[PositionIn]):
    global latest_positions
    latest_positions = [p.model_dump() for p in positions]
    return {"status": "ok", "count": len(latest_positions)}

@app.get("/positions")
def get_positions():
    return latest_positions

@app.post("/account")
def update_account(acc: AccountIn):
    global latest_account
    latest_account = acc.model_dump()
    return {"status": "ok"}

@app.get("/account")
def get_account():
    return latest_account or {}


from fastapi.responses import StreamingResponse
import io

@app.get("/export/csv")
def export_csv():
    conn = get_db()
    rows = conn.execute("SELECT * FROM decisions ORDER BY id ASC").fetchall()
    conn.close()
    output = io.StringIO()
    output.write("id,action,direction,symbol,price,score,context_strength,fg_score,rsi,reason,rule_hit,lot_size,risk_percent,source,created_at\n")
    for r in rows:
        line = ",".join([
            str(r["id"]),
            r["action"] or "",
            r["direction"] or "",
            r["symbol"] or "",
            str(r["price"] or ""),
            str(r["score"] or ""),
            str(r["context_strength"] or ""),
            str(r["fg_score"] or ""),
            str(r["rsi"] or ""),
            '"' + (r["reason"] or "").replace('"', '""') + '"',
            r["rule_hit"] or "",
            str(r["lot_size"] or ""),
            str(r["risk_percent"] or ""),
            r["source"] or "",
            r["created_at"] or ""
        ])
        output.write(line + "\n")
    output.seek(0)
    return StreamingResponse(
        iter([output.getvalue()]),
        media_type="text/csv",
        headers={"Content-Disposition": "attachment; filename=botgold_decisions.csv"}
    )

@app.delete("/decisions")
def clear_decisions():
    """Efface tout l'historique (dev uniquement)."""
    conn = get_db()
    conn.execute("DELETE FROM decisions")
    conn.commit()
    conn.close()
    return {"cleared": True}
