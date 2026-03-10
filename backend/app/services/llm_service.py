"""
LLM Service — Gemini Integration
Transforms raw mathematical evaluation results into human-readable AI insights.
This service is intentionally stateless and pure; it receives context, builds a
structured prompt, calls Gemini, and returns a narrative string.
"""
import logging
import google.generativeai as genai

from app.core.config import settings
from app.services.decision_engine import EvaluationResult

logger = logging.getLogger(__name__)

# --- Model Configuration ---
GEMINI_MODEL = "gemini-1.5-flash"

# Configure Gemini once at module level
if settings.GEMINI_API_KEY:
    genai.configure(api_key=settings.GEMINI_API_KEY)

def _build_prompt(
    item_name: str,
    item_price_cents: int,
    result: EvaluationResult,
    user_goals_context: list[dict],
    upcoming_expenses_context: list[dict],
) -> str:
    """
    Constructs a highly specific, structured prompt.
    We hand the model NUMBERS, not vague descriptions, so its reasoning is grounded.
    """
    price_display = f"${item_price_cents / 100:.2f}"

    # Format goal delays into a readable sentence
    goal_delay_parts = []
    for goal_id, delay_days in result.goals_delayed.items():
        # Find the matching goal name from context
        goal_name = next((g["name"] for g in user_goals_context if g["id"] == goal_id), goal_id)
        goal_delay_parts.append(f"'{goal_name}' delayed by {delay_days:.1f} days")
    goal_summary = ", ".join(goal_delay_parts) if goal_delay_parts else "No savings goals affected."

    # Format upcoming critical expenses
    upcoming = ", ".join(
        [f"${e['amount_cents'] / 100:.2f} {e['name']} due on day {e['due_date_day']}"
         for e in upcoming_expenses_context if e.get("due_date_day")]
    ) or "None currently tracked."

    # Determine the user's situation type for framing
    if result.deficit_mode:
        situation_framing = "The user is currently in DEFICIT MODE — they are already overspending each cycle."
    elif result.liquidity_failure:
        situation_framing = f"This purchase would cause a LIQUIDITY FAILURE — the user would run out of cash on at least one day before their next paycheck due to this {price_display} purchase."
    else:
        situation_framing = f"The user CAN afford this purchase mathematically, but it carries a '{result.risk_level}' classification."

    prompt = f"""You are Mizan's financial advisor AI. Your job is to give brutally honest, clear, and empathetic financial guidance in 2-3 concise sentences. Do NOT be preachy. Do NOT use bullet points. Write in a calm, direct tone — like a trusted advisor.

PURCHASE UNDER REVIEW: '{item_name}' costing {price_display}

MATHEMATICAL ANALYSIS FROM THE ENGINE:
- Risk Level: {result.risk_level}
- Affordability Score: {result.affordability_score}/100
- Days of safe spending this purchase wipes out: {result.days_impacted} days
- Liquidity failure triggered: {result.liquidity_failure}
- Deficit mode: {result.deficit_mode}
- Savings goal impact: {goal_summary}
- Upcoming fixed expenses within cycle: {upcoming}

SITUATION SUMMARY: {situation_framing}

Write your AI Insight now (2-3 sentences max, no lists, no headers):"""

    return prompt


async def generate_insight(
    item_name: str,
    item_price_cents: int,
    result: EvaluationResult,
    user_goals_context: list[dict] | None = None,
    upcoming_expenses_context: list[dict] | None = None,
) -> str:
    """
    Main entry point for the LLM service.
    Calls Gemini and returns the AI-generated insight string.
    Falls back gracefully if the API key is missing or the call fails.
    """
    if not settings.GEMINI_API_KEY:
        logger.warning("GEMINI_API_KEY is not set. Returning fallback insight.")
        return _fallback_insight(result)

    user_goals_context = user_goals_context or []
    upcoming_expenses_context = upcoming_expenses_context or []

    try:
        model = genai.GenerativeModel(GEMINI_MODEL)

        prompt = _build_prompt(
            item_name, item_price_cents, result,
            user_goals_context, upcoming_expenses_context
        )

        response = await model.generate_content_async(prompt)
        return response.text.strip()

    except Exception as e:
        logger.error(f"Gemini LLM call failed: {e}")
        return _fallback_insight(result)


def _fallback_insight(result: EvaluationResult) -> str:
    """
    Returns a deterministic, math-generated insight when Gemini is unavailable.
    Ensures the feature never breaks the user experience.
    """
    if result.deficit_mode:
        return "You are currently spending more than you earn each cycle. Any additional purchase will widen this gap."
    if result.liquidity_failure:
        return f"This purchase would drain your available cash before your next income event. Consider waiting until after your next paycheck."
    if result.affordability_score >= 75:
        return f"This purchase looks manageable. It uses {100 - result.affordability_score}% of your safe buffer and has minimal impact on your goals."
    return f"This purchase places heavy pressure on your finances, wiping out {result.days_impacted:.0f} days of safe spending capacity. Strong caution advised."

def _build_reflection_prompt(purchase: "PurchaseModel", reflection: "ReflectionCreate", error_pct: float | None) -> str:
    """
    Constructs a prompt for the 7/30 day post-mortem based on predicted vs actual impact.
    """
    pressure_status = "You DID feel financial pressure." if reflection.felt_financial_pressure else "You DID NOT feel financial pressure."
    regret_str = f"You rated your regret a {reflection.regret_score}/5." if reflection.regret_score else "No regret rating provided."

    error_analysis = ""
    if error_pct is not None:
        if error_pct > 0.15:
            error_analysis = f"The actual financial impact ({reflection.actual_days_impacted} days) was WORSE than Mizan predicted ({purchase.days_impacted_predicted} days)."
        elif error_pct < -0.15:
            error_analysis = f"The actual financial impact ({reflection.actual_days_impacted} days) was LIGHTER than Mizan predicted ({purchase.days_impacted_predicted} days)."
        else:
            error_analysis = f"Mizan's prediction ({purchase.days_impacted_predicted} days) was highly accurate to your actual experience ({reflection.actual_days_impacted} days)."

    prompt = f"""You are Mizan's AI financial reflection coach. The user is doing a {reflection.window_days}-day post-mortem on a purchase. Write 2-3 sentences of empathetic, analytical feedback. Do NOT be preachy.

PAST PURCHASE: '{purchase.item_name}' for ${purchase.price_cents / 100:.2f}
MIZAN'S ORIGINAL PREDICTION: Risk was '{purchase.risk_level}'. Affordability score was {purchase.affordability_score}/100.
ACTUAL EXPERIENCE: {pressure_status} {regret_str}
DATA ANALYSIS: {error_analysis}

Based on this, what is the core lesson the user should take away from this purchase? (No bullet points, no headers)"""
    return prompt

async def generate_reflection_insight(purchase: "PurchaseModel", reflection: "ReflectionCreate", error_pct: float | None) -> str:
    """
    Generates a post-mortem learning insight based on actual vs predicted behavior.
    """
    if not settings.GEMINI_API_KEY:
        return "Reflection recorded. Tracking your actual outcomes helps build better financial habits over time."

    try:
        model = genai.GenerativeModel(GEMINI_MODEL)
        prompt = _build_reflection_prompt(purchase, reflection, error_pct)
        response = await model.generate_content_async(prompt)
        return response.text.strip()
    except Exception as e:
        logger.error(f"Gemini Reflection call failed: {e}")
        return "Reflection recorded. Tracking your actual outcomes helps build better financial habits over time."
