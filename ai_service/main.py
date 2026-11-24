"""
FastAPI Microservice for Smart Finance AI
Provides endpoints for Wastage Analysis, Income Strategies, Monthly Briefing,
Chat Q&A, and Voice Command Parsing.
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Any, Optional

from financial_analysis import (
    analyze_wastage,
    analyze_income_improvement,
    generate_monthly_ai_summary
)
from prompt_templates import (
    parse_voice_command,
    answer_financial_question
)

app = FastAPI(
    title="Smart Finance AI Engine",
    description="Intelligent financial analytics, voice intent parsing, and advisory service",
    version="1.0.0"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class WastageRequest(BaseModel):
    transactions: List[Dict[str, Any]]
    monthly_income: float = 0.0


class IncomeStrategyRequest(BaseModel):
    transactions: List[Dict[str, Any]]
    total_income: float
    total_expense: float
    savings_goals: Optional[List[Dict[str, Any]]] = None


class MonthlySummaryRequest(BaseModel):
    current_month: Dict[str, Any]
    previous_month: Optional[Dict[str, Any]] = None


class VoiceParseRequest(BaseModel):
    text: str
    language: str = "en"


class ChatRequest(BaseModel):
    question: str
    context: Dict[str, Any]


@app.get("/health")
def health_check():
    return {"status": "ok", "service": "Smart Finance AI Service", "version": "1.0.0"}


@app.post("/analyse/wastage")
def post_analyze_wastage(req: WastageRequest):
    try:
        result = analyze_wastage(req.transactions, req.monthly_income)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/analyse/income")
def post_analyze_income(req: IncomeStrategyRequest):
    try:
        result = analyze_income_improvement(
            req.transactions,
            req.total_income,
            req.total_expense,
            req.savings_goals
        )
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/analyse/monthly-summary")
def post_monthly_summary(req: MonthlySummaryRequest):
    try:
        result = generate_monthly_ai_summary(req.current_month, req.previous_month)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/voice/parse")
def post_parse_voice(req: VoiceParseRequest):
    try:
        result = parse_voice_command(req.text, req.language)
        return {"success": True, "data": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/chat")
def post_chat_reply(req: ChatRequest):
    try:
        answer = answer_financial_question(req.question, req.context)
        return {"success": True, "data": {"answer": answer}}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
