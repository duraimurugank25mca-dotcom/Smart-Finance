"""
Financial Analysis Engine for Smart Finance Manager
Includes wastage detection, anomaly identification, recurring spend detection,
income improvement strategies, and monthly analytical summaries.
"""

from datetime import datetime, date
from typing import List, Dict, Any, Optional
import math


def calculate_anomalies(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Identifies unusually high spending transactions using statistical Z-score / IQR.
    """
    expenses = [
        float(t["amount"])
        for t in transactions
        if t.get("type") == "expense" and float(t.get("amount", 0)) > 0
    ]

    if len(expenses) < 3:
        return []

    mean = sum(expenses) / len(expenses)
    variance = sum((x - mean) ** 2 for x in expenses) / len(expenses)
    std_dev = math.sqrt(variance) if variance > 0 else 0

    threshold = mean + (1.8 * std_dev)

    anomalies = []
    for t in transactions:
        amt = float(t.get("amount", 0))
        if t.get("type") == "expense" and amt > threshold and amt > 1000:
            anomalies.append({
                "transaction_id": t.get("id"),
                "amount": amt,
                "category": t.get("category_name", "General"),
                "date": str(t.get("transaction_date")),
                "description": t.get("description", ""),
                "deviation_score": round((amt - mean) / (std_dev if std_dev > 0 else 1), 1),
                "insight": f"₹{amt:,.0f} spent on {t.get('category_name')} is significantly higher than your typical average of ₹{mean:,.0f}."
            })

    return anomalies[:5]


def identify_repeated_purchases(transactions: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
    """
    Detects frequently repeated micro-transactions (e.g. food delivery, cafe, shopping).
    """
    category_counts: Dict[str, Dict[str, Any]] = {}

    for t in transactions:
        if t.get("type") != "expense":
            continue
        cat = t.get("category_name", "Other")
        amt = float(t.get("amount", 0))

        if cat not in category_counts:
            category_counts[cat] = {"count": 0, "total": 0.0, "items": []}

        category_counts[cat]["count"] += 1
        category_counts[cat]["total"] += amt
        category_counts[cat]["items"].append(t.get("description") or cat)

    repeated = []
    for cat, data in category_counts.items():
        if data["count"] >= 3 and cat in ["Food", "Shopping", "Entertainment", "Other expenses"]:
            avg_per_tx = data["total"] / data["count"]
            repeated.append({
                "category": cat,
                "frequency": data["count"],
                "total_spent": round(data["total"], 2),
                "average_per_spend": round(avg_per_tx, 2),
                "insight": f"You made {data['count']} purchases in {cat} totaling ₹{data['total']:,.0f}. Consolidating or setting a weekly budget could reduce impulsive micro-spending."
            })

    return sorted(repeated, key=lambda x: x["total_spent"], reverse=True)


def analyze_wastage(transactions: List[Dict[str, Any]], monthly_income: float) -> Dict[str, Any]:
    """
    Comprehensive wastage cost analysis:
    - Unusually high spending
    - High-discretionary category spending
    - Repeated small expenses
    - Actionable cost-saving recommendations
    """
    anomalies = calculate_anomalies(transactions)
    repeated = identify_repeated_purchases(transactions)

    total_expense = sum(
        float(t["amount"])
        for t in transactions
        if t.get("type") == "expense"
    )

    # Discretionary categories (Food eating out, Entertainment, Shopping)
    discretionary_categories = ["Food", "Shopping", "Entertainment", "Other expenses"]
    discretionary_total = sum(
        float(t["amount"])
        for t in transactions
        if t.get("type") == "expense" and t.get("category_name") in discretionary_categories
    )

    discretionary_ratio = (discretionary_total / total_expense * 100) if total_expense > 0 else 0

    recommendations = []
    potential_savings = 0.0

    if discretionary_ratio > 35:
        save_target = discretionary_total * 0.20
        potential_savings += save_target
        recommendations.append(
            f"Discretionary spending (Food/Shopping/Entertainment) accounts for {discretionary_ratio:.1f}% of your expenses. Capping weekend dining and non-essential shopping could save approx ₹{save_target:,.0f} this month."
        )

    for rep in repeated:
        if rep["frequency"] >= 4:
            potential_cut = rep["total_spent"] * 0.25
            potential_savings += potential_cut
            recommendations.append(
                f"Frequent {rep['category']} spends detected ({rep['frequency']} times, total ₹{rep['total_spent']:,.0f}). Limiting orders to planned days can save ~₹{potential_cut:,.0f}."
            )

    if anomalies:
        recommendations.append(
            f"{len(anomalies)} unusually large expense transactions detected. Review these purchases to confirm whether recurring commitments or one-time necessities."
        )

    if not recommendations:
        recommendations.append("Your spending discipline is steady! Continue monitoring recurring subscriptions and seasonal promotions.")

    return {
        "anomalies": anomalies,
        "repeated_purchases": repeated,
        "discretionary_total": round(discretionary_total, 2),
        "discretionary_percentage": round(discretionary_ratio, 1),
        "estimated_monthly_wastage_potential": round(potential_savings, 2),
        "recommendations": recommendations,
        "severity": "high" if discretionary_ratio > 45 else ("medium" if discretionary_ratio > 25 else "low")
    }


def analyze_income_improvement(
    transactions: List[Dict[str, Any]],
    total_income: float,
    total_expense: float,
    savings_goals: Optional[List[Dict[str, Any]]] = None
) -> Dict[str, Any]:
    """
    Identifies realistic avenues to improve savings rate, evaluate income diversity,
    and build safety buffers without making speculative guarantees.
    """
    net_savings = total_income - total_expense
    savings_rate = (net_savings / total_income * 100) if total_income > 0 else 0

    # Check income diversity
    income_categories = set(
        t.get("category_name", "Other")
        for t in transactions
        if t.get("type") == "income"
    )

    strategies = []
    recommended_emergency_fund = max(50000.0, total_expense * 3)

    if len(income_categories) <= 1:
        strategies.append(
            "Primary reliance on a single income stream detected. Consider building secondary income streams (freelancing, consulting, or monetizing specialized skills)."
        )

    if savings_rate < 20:
        strategies.append(
            f"Current savings rate is {savings_rate:.1f}%. Aim for a standard 50/30/20 budget (50% essentials, 30% wants, 20% savings) to build an initial buffer."
        )
    elif savings_rate >= 30:
        strategies.append(
            f"Strong savings rate of {savings_rate:.1f}%! Maintain this surplus into recurring liquid savings and your active target goals."
        )

    strategies.append(
        f"Recommended emergency fund: ₹{recommended_emergency_fund:,.0f} (equivalent to 3 months of baseline living expenses)."
    )

    return {
        "current_savings_rate": round(savings_rate, 1),
        "income_streams_count": len(income_categories),
        "recommended_emergency_fund": round(recommended_emergency_fund, 2),
        "net_surplus": round(net_savings, 2),
        "strategies": strategies
    }


def generate_monthly_ai_summary(
    current_month_data: Dict[str, Any],
    previous_month_data: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Generates an executive monthly financial briefing comparing month-over-month.
    """
    curr_inc = float(current_month_data.get("income", 0))
    curr_exp = float(current_month_data.get("expense", 0))
    curr_sav = curr_inc - curr_exp
    curr_rate = (curr_sav / curr_inc * 100) if curr_inc > 0 else 0

    prev_inc = float(previous_month_data.get("income", 0)) if previous_month_data else curr_inc
    prev_exp = float(previous_month_data.get("expense", 0)) if previous_month_data else curr_exp

    income_growth = ((curr_inc - prev_inc) / prev_inc * 100) if prev_inc > 0 else 0
    expense_growth = ((curr_exp - prev_exp) / prev_exp * 100) if prev_exp > 0 else 0

    highlights = []
    if income_growth > 0:
        highlights.append(f"Income grew by +{income_growth:.1f}% compared to last month.")
    elif income_growth < 0:
        highlights.append(f"Income decreased by {income_growth:.1f}% compared to last month.")

    if expense_growth > 5:
        highlights.append(f"Expenses increased by +{expense_growth:.1f}%. Review top expenditure categories.")
    elif expense_growth < 0:
        highlights.append(f"Great progress! Expenses dropped by {abs(expense_growth):.1f}%.")

    return {
        "month": current_month_data.get("month", "Current Month"),
        "total_income": curr_inc,
        "total_expenses": curr_exp,
        "net_savings": curr_sav,
        "savings_rate_percentage": round(curr_rate, 1),
        "income_growth_percentage": round(income_growth, 1),
        "expense_growth_percentage": round(expense_growth, 1),
        "highlights": highlights,
        "financial_health_score": min(100, max(20, int(50 + (curr_rate * 1.2) - (max(0, expense_growth) * 0.5))))
    }
