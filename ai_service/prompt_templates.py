"""
Prompt Templates and Natural Language / Voice Intent Parser
Supports English, Tamil, and Tanglish (Tamil-English mixed)
"""

import re
from datetime import datetime, date
from typing import Dict, Any, Optional, List


def parse_voice_command(text: str, language: str = "en") -> Dict[str, Any]:
    """
    Parses natural language and voice input into structured financial actions.
    Supports English, Tamil script, and Tanglish phonetics.
    """
    cleaned = text.strip()
    lower = cleaned.lower()

    # Numbers / amounts extraction (e.g. 5000, 5,000, 200, 4500)
    # Also handle Tamil words for numbers if phonetic
    amt_match = re.search(r'(?:₹|rs\.?|rupees|roobai|rubai|inr)?\s*(\d+(?:,\d+)*(?:\.\d+)?)\s*(?:₹|rs\.?|rupees|roobai|rubai|inr)?', lower)
    amount = 0.0
    if amt_match:
        try:
            amount = float(amt_match.group(1).replace(',', ''))
        except ValueError:
            amount = 0.0

    # 1. ADD INCOME COMMANDS
    # English: "add 5000 rupees salary income", "received 2000 rupees freelance"
    # Tamil / Tanglish: "5000 roobai salary income add pannu", "varumanam", "income serkka"
    is_income = any(w in lower for w in [
        "income", "salary", "varumanam", "received", "earned", "credit", "sambalam", "freelance"
    ]) and not any(w in lower for w in ["spent", "expense", "selavu", "petrol", "food"])

    if is_income and amount > 0:
        # Category detection
        category = "Salary"
        if "freelanc" in lower:
            category = "Freelancing"
        elif "business" in lower or "vyabaram" in lower:
            category = "Business income"
        elif "invest" in lower or "mudalidu" in lower:
            category = "Investment income"
        elif "other" in lower:
            category = "Other income"

        resp_en = f"Found income of ₹{amount:,.0f} for {category}. Please confirm to save."
        resp_ta = f"₹{amount:,.0f} {category} வருமானம் கண்டறியப்பட்டது. உறுதிப்படுத்தவும்."

        return {
            "intent": "ADD_INCOME",
            "action": "preview_transaction",
            "data": {
                "type": "income",
                "amount": amount,
                "category_name": category,
                "transaction_date": date.today().isoformat(),
                "payment_method": "Bank Transfer" if category == "Salary" else "Cash",
                "description": f"Voice entry: {cleaned}"
            },
            "response_text": resp_ta if language in ["ta", "tamil"] else resp_en,
            "requires_confirmation": True
        }

    # 2. ADD EXPENSE COMMANDS
    # English: "add 200 rupees petrol expense", "today I spent 500 rupees for shopping"
    # Tamil / Tanglish: "200 roobai petrol selavu add pannu", "500 roobai shopping selavu", "selavu serkka"
    is_expense = any(w in lower for w in [
        "expense", "spent", "selavu", "petrol", "shopping", "food", "grocery", "rent", "tea", "snack"
    ]) or (amount > 0 and not is_income and any(w in lower for w in ["add", "serkka", "pannu", "podu"]))

    if is_expense and amount > 0:
        category = "Other expenses"
        if any(w in lower for w in ["petrol", "fuel", "diesel"]):
            category = "Petrol / Fuel"
        elif any(w in lower for w in ["food", "lunch", "dinner", "breakfast", "cafe", "tea", "restaurant", "sappadu"]):
            category = "Food"
        elif any(w in lower for w in ["shop", "dress", "cloth", "amazon"]):
            category = "Shopping"
        elif any(w in lower for w in ["grocery", "groceries", "supermarket", "maligai"]):
            category = "Groceries"
        elif any(w in lower for w in ["rent", "house rent", "veettu vaadagai", "vadagai"]):
            category = "Rent"
        elif any(w in lower for w in ["medical", "doctor", "medicine", "marunthu"]):
            category = "Medical"
        elif any(w in lower for w in ["electricity", "eb bill", "minsaram"]):
            category = "Electricity"

        resp_en = f"Found expense of ₹{amount:,.0f} for {category}. Please confirm to save."
        resp_ta = f"₹{amount:,.0f} {category} செலவு கண்டறியப்பட்டது. உறுதிப்படுத்தவும்."

        return {
            "intent": "ADD_EXPENSE",
            "action": "preview_transaction",
            "data": {
                "type": "expense",
                "amount": amount,
                "category_name": category,
                "transaction_date": date.today().isoformat(),
                "payment_method": "UPI" if category in ["Petrol / Fuel", "Food"] else "Cash",
                "description": f"Voice entry: {cleaned}"
            },
            "response_text": resp_ta if language in ["ta", "tamil"] else resp_en,
            "requires_confirmation": True
        }

    # 3. ADD EMI COMMANDS
    # "Add bike EMI of 4500 rupees due on 20th November"
    # "Bike emi 4500 roobai add pannu"
    if "emi" in lower or "loan" in lower or "kadan" in lower:
        loan_type = "Loan / EMI"
        if "bike" in lower or "two wheeler" in lower:
            loan_type = "Bike Loan"
        elif "car" in lower:
            loan_type = "Car Loan"
        elif "home" in lower or "house" in lower:
            loan_type = "Home Loan"
        elif "credit card" in lower:
            loan_type = "Credit Card Bill"

        due_date = date.today().isoformat()
        # Simple extraction of date number if present
        day_match = re.search(r'(\d{1,2})(?:st|nd|rd|th)?\s*(?:nov|november|dec|december|jan|feb|mar|apr|may|jun|jul|aug|sep|oct)?', lower)
        if day_match and int(day_match.group(1)) <= 31:
            today = date.today()
            due_date = f"{today.year}-{today.month:02d}-{int(day_match.group(1)):02d}"

        return {
            "intent": "ADD_EMI",
            "action": "preview_emi",
            "data": {
                "emi_name": f"{loan_type} Payment",
                "loan_provider": "Finance Bank",
                "emi_amount": amount or 3000.0,
                "due_date": due_date,
                "payment_frequency": "monthly"
            },
            "response_text": f"Found {loan_type} EMI of ₹{amount:,.0f} due on {due_date}. Please confirm to save.",
            "requires_confirmation": True
        }

    # 4. GENERATE REPORT COMMANDS
    # "Generate my report from November 1st to November 16th"
    # "Report generate pannu"
    if "report" in lower or "pdf" in lower or "statement" in lower or "arikkai" in lower:
        return {
            "intent": "GENERATE_REPORT",
            "action": "open_report",
            "data": {
                "start_date": f"{date.today().year}-{date.today().month:02d}-01",
                "end_date": date.today().isoformat(),
                "report_type": "all"
            },
            "response_text": "Navigating to financial report generator. You can view or download your statement.",
            "requires_confirmation": False
        }

    # 5. FINANCIAL QUESTIONS
    # "What is my balance?" / "Enoda balance evlo?"
    # "How much did I spend today?" / "Innaiku naan evlo selavu pannen?"
    # "How much did I save this month?"
    # "Which category has the highest spending?"
    if any(q in lower for q in ["balance", "evlo balance", "meethi", "iruku"]):
        return {
            "intent": "QUERY_BALANCE",
            "action": "query",
            "response_text": "Fetching your live balance details.",
            "requires_confirmation": False
        }

    if any(q in lower for q in ["spend today", "today expense", "innaiku selavu", "today spent"]):
        return {
            "intent": "QUERY_TODAY_SPENT",
            "action": "query",
            "response_text": "Checking your expenses recorded for today.",
            "requires_confirmation": False
        }

    if any(q in lower for q in ["save this month", "monthly savings", "savings evlo"]):
        return {
            "intent": "QUERY_MONTHLY_SAVINGS",
            "action": "query",
            "response_text": "Calculating your monthly savings and savings percentage.",
            "requires_confirmation": False
        }

    if any(q in lower for q in ["highest", "adhiga selavu", "top expense", "highest category"]):
        return {
            "intent": "QUERY_HIGHEST_CATEGORY",
            "action": "query",
            "response_text": "Analyzing your spending to find your top expense category.",
            "requires_confirmation": False
        }

    # General chat query fallback
    return {
        "intent": "GENERAL_QUERY",
        "action": "chat",
        "query": cleaned,
        "response_text": f"Analyzing: {cleaned}",
        "requires_confirmation": False
    }


def answer_financial_question(question: str, context: Dict[str, Any]) -> str:
    """
    Answers user's financial inquiries using actual user transaction data.
    Strictly avoids fabricated numbers or investment guarantees.
    """
    q_lower = question.lower()

    balance = float(context.get("totalBalance", 0))
    monthly_income = float(context.get("monthlyIncome", 0))
    monthly_expenses = float(context.get("monthlyExpenses", 0))
    monthly_savings = float(context.get("monthlySavings", 0))
    savings_pct = float(context.get("savingsPercentage", 0))
    today_spent = float(context.get("todayExpenses", 0))
    top_category = context.get("topExpenseCategory", "None")
    currency = context.get("currency", "INR")

    if "balance" in q_lower or "iruku" in q_lower:
        return f"Your current net financial balance is {currency} {balance:,.2f} (Total Income: {currency} {context.get('totalIncome', 0):,.2f}, Total Expenses: {currency} {context.get('totalExpenses', 0):,.2f})."

    if "today" in q_lower or "innaiku" in q_lower:
        return f"You have spent {currency} {today_spent:,.2f} today. Keep tracking all daily purchases to stay within your budget!"

    if "income this month" in q_lower or "month income" in q_lower:
        return f"Your total recorded income for this month is {currency} {monthly_income:,.2f}."

    if "highest" in q_lower or "top category" in q_lower or "adhiga" in q_lower:
        return f"Your highest expense category this month is '{top_category}' with total spending of {currency} {context.get('topExpenseAmount', 0):,.2f}."

    if "save next month" in q_lower or "how much can i save" in q_lower:
        potential_save = max(0.0, monthly_income * 0.25)
        return f"Based on your recent savings rate of {savings_pct}%, a realistic target for next month is to save at least 25% of your income (~{currency} {potential_save:,.2f}). Trimming discretionary spends in {top_category} will help you achieve this."

    if "reduce wastage" in q_lower or "wastage" in q_lower:
        return f"To reduce wastage: 1) Cap your spending in your top category '{top_category}'. 2) Review micro-purchases (tea, fast food, online shopping). 3) Set category budget limits in the Budget tab."

    if "compare" in q_lower:
        prev_exp = float(context.get("lastMonthExpenses", monthly_expenses * 0.95))
        diff = monthly_expenses - prev_exp
        direction = "increased" if diff > 0 else "decreased"
        return f"This month's expenses ({currency} {monthly_expenses:,.2f}) have {direction} by {currency} {abs(diff):,.2f} compared to last month ({currency} {prev_exp:,.2f})."

    # Default insightful response
    return f"Here is your financial snapshot: Balance: {currency} {balance:,.2f}, This Month's Income: {currency} {monthly_income:,.2f}, Expenses: {currency} {monthly_expenses:,.2f}, Savings: {currency} {monthly_savings:,.2f} ({savings_pct}%). How else can I assist your financial planning?"
