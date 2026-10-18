import os
import json
from datetime import datetime

import snowflake.connector
from dotenv import load_dotenv
from ollama import Client


# ============================================================
# 1. CONFIGURATION
# ============================================================

load_dotenv()

MAIN_TEXT_MODEL = "gpt-oss:120b-cloud"
BATCH_SIZE = 20  # Nombre d'avis traités par lot

ollama_client = Client(
    host="http://localhost:11434",
    headers={
        "Authorization": f"Bearer {os.getenv('OLLAMA_API_KEY')}"
    }
)


# ============================================================
# 2. SNOWFLAKE CONNECTION
# ============================================================

connection = snowflake.connector.connect(
    account=os.getenv("SNOWFLAKE_ACCOUNT"),
    user=os.getenv("SNOWFLAKE_USER"),
    password=os.getenv("SNOWFLAKE_PASSWORD"),
    warehouse=os.getenv("SNOWFLAKE_WAREHOUSE"),
    database=os.getenv("SNOWFLAKE_DATABASE"),
    schema="STAGING",
    role=os.getenv("SNOWFLAKE_ROLE")
)

cursor = connection.cursor()


# ============================================================
# 3. ALLOWED CATEGORIES
# ============================================================

ALLOWED_CAUSES = [
    "PRODUCT_QUALITY",
    "PRODUCT_DESCRIPTION",
    "PRODUCT_SIZE",
    "DELIVERY_DELAY",
    "DELIVERY_SPEED",
    "DAMAGED_PACKAGE",
    "PACKAGING",
    "PRICE_VALUE",
    "PAYMENT",
    "CUSTOMER_SERVICE",
    "ORDER_ACCURACY",
    "PRODUCT_SATISFACTION",
    "OTHER",
    "NO_REASON"
]


# ============================================================
# 4. FETCH COMMENTS
# ============================================================

select_query = """
SELECT
    r.review_id,
    r.order_id,
    r.review_score,
    r.review_comment_message

FROM OLIST_DWH.STAGING.STG_ORDER_REVIEWS r

WHERE r.review_comment_message IS NOT NULL
  AND TRIM(r.review_comment_message) <> ''
  AND NOT EXISTS (
      SELECT 1 
      FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION f 
      WHERE f.review_id = r.review_id 
        AND f.order_id = r.order_id
  )
"""

cursor.execute(select_query)

reviews = cursor.fetchall()

print(f"Number of remaining reviews fetched: {len(reviews)}")


# ============================================================
# 5. BATCH ANALYSIS AND TRANSLATION WITH OLLAMA
# ============================================================

def analyze_batch_reviews(batch_reviews) -> list:
    
    formatted_batch = []
    for review_id, order_id, review_score, comment in batch_reviews:
        formatted_batch.append({
            "review_id": review_id,
            "order_id": order_id,
            "review_score": review_score,
            "comment": comment
        })

    prompt = f"""
You are a customer satisfaction analyst
for a Brazilian e-commerce company.

Analyze the following batch of customer reviews. 
The comments may potentially be in Brazilian Portuguese.

Allowed categories:
{", ".join(ALLOWED_CAUSES)}

Input batch of reviews (JSON format):
{json.dumps(formatted_batch, ensure_ascii=False)}

Return ONLY a valid JSON array containing an analysis object for each review, matching this exact structure:
[
    {{
        "review_id": "...",
        "order_id": "...",
        "sentiment_label": "POSITIVE",
        "sentiment_confidence": 0.0,
        "main_cause": "NO_REASON",
        "cause_labels": [],
        "evidence_text": "",
        "comment_translated_en": "",
        "evidence_text_en": ""
    }}
]

Mandatory rules:

1. sentiment_label must be:
   POSITIVE, NEGATIVE, NEUTRAL or MIXED.

2. sentiment_confidence must be a number between 0 and 1.

3. main_cause must belong to the allowed categories.

4. cause_labels must contain only allowed categories.

5. evidence_text must be a short excerpt
   actually present in the original comment.

6. evidence_text must be kept in its original language.

7. comment_translated_en must be a faithful
   and complete English translation of the comment.

8. evidence_text_en must be the faithful English translation
   of evidence_text.

9. Do not invent information absent from the comment.

10. If no cause is identifiable:
    main_cause = NO_REASON.

11. Return only the JSON array, without Markdown.
"""

    response = ollama_client.chat(
        model=MAIN_TEXT_MODEL,
        messages=[
            {
                "role": "user",
                "content": prompt
            }
        ],
        options={
            "temperature": 0.3
        }
    )

    response_text = response["message"]["content"].strip()

    if response_text.startswith("```json"):
        response_text = response_text[7:]
    if response_text.startswith("```"):
        response_text = response_text[3:]
    if response_text.endswith("```"):
        response_text = response_text[:-3]

    return json.loads(response_text.strip())


# ============================================================
# 6. RESULT VALIDATION
# ============================================================

def validate_result(result: dict, original_comment: str) -> bool:

    valid_sentiments = {
        "POSITIVE",
        "NEGATIVE",
        "NEUTRAL",
        "MIXED"
    }

    if result.get("sentiment_label") not in valid_sentiments:
        return False

    confidence = result.get("sentiment_confidence")

    if (
        not isinstance(confidence, (int, float))
        or isinstance(confidence, bool)
        or not 0 <= confidence <= 1
    ):
        return False

    if result.get("main_cause") not in ALLOWED_CAUSES:
        return False

    cause_labels = result.get("cause_labels", [])

    if not isinstance(cause_labels, list):
        return False

    for cause in cause_labels:
        if cause not in ALLOWED_CAUSES:
            return False

    evidence_text = result.get("evidence_text", "")

    if not isinstance(evidence_text, str):
        return False

    if evidence_text.strip() != "":
        if evidence_text.lower() not in original_comment.lower():
            return False

    comment_translated_en = result.get(
        "comment_translated_en",
        ""
    )

    evidence_text_en = result.get(
        "evidence_text_en",
        ""
    )

    if not isinstance(comment_translated_en, str):
        return False

    if not isinstance(evidence_text_en, str):
        return False

    return True


# ============================================================
# 7. INSERTION QUERY INTO FACT_REVIEW_SATISFACTION
# ============================================================

insert_query = """
INSERT INTO OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION (
    analysis_key,
    review_id,
    order_id,
    review_score,
    comment_original,
    comment_translated_en,
    sentiment_label,
    sentiment_confidence,
    main_cause,
    cause_labels,
    evidence_text,
    evidence_text_en,
    model_name,
    analysis_timestamp
)
SELECT
    %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s
WHERE NOT EXISTS (
    SELECT 1
    FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
    WHERE analysis_key = %s
)
"""


# ============================================================
# 8. BATCH PROCESSING REVIEWS
# ============================================================

for i in range(0, len(reviews), BATCH_SIZE):
    batch = reviews[i:i + BATCH_SIZE]
    print(f"\nProcessing batch {i // BATCH_SIZE + 1} (Reviews {i} to {i + len(batch) - 1})...")

    try:
        results = analyze_batch_reviews(batch)
        
        if not isinstance(results, list):
            print("Warning: LLM did not return a list. Skipping batch.")
            continue

        result_map = {}
        for res in results:
            if isinstance(res, dict) and "review_id" in res and "order_id" in res:
                res_key = f"{res.get('review_id')}|{res.get('order_id')}"
                result_map[res_key] = res

        inserted_count = 0

        for review_id, order_id, review_score, comment in batch:
            analysis_key = f"{review_id}|{order_id}"
            result = result_map.get(analysis_key)

            if not result:
                print(f"Invalid result for {analysis_key}: skipped (not found in LLM response).")
                continue

            if not validate_result(result, comment):
                print(f"Invalid result for {analysis_key}: skipped (validation failed).")
                continue

            cause_labels = "|".join(
                result.get("cause_labels", [])
            )

            try:
                cursor.execute(
                    insert_query,
                    (
                        analysis_key,
                        review_id,
                        order_id,
                        review_score,
                        comment,
                        result["comment_translated_en"],
                        result["sentiment_label"],
                        result["sentiment_confidence"],
                        result["main_cause"],
                        cause_labels,
                        result["evidence_text"],
                        result["evidence_text_en"],
                        MAIN_TEXT_MODEL,
                        datetime.now(),
                        analysis_key
                    )
                )
                inserted_count += 1
            except Exception as insert_err:
                print(f"Error inserting {analysis_key}: {insert_err}")

        connection.commit()
        print(f"Batch successfully saved: {inserted_count} records inserted.")

    except json.JSONDecodeError as error:
        print(f"JSON error in batch: {error}")

    except Exception as error:
        print(f"Error processing batch: {error}")


# ============================================================
# 9. TRAITEMENT DES REVIEWS SANS COMMENTAIRE
# ============================================================

print("\nProcessing reviews without comments...")

insert_no_comment_query = """
INSERT INTO OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION (
    analysis_key,
    review_id,
    order_id,
    review_score,
    comment_original,
    comment_translated_en,
    sentiment_label,
    sentiment_confidence,
    main_cause,
    cause_labels,
    evidence_text,
    evidence_text_en,
    model_name,
    analysis_timestamp
)
SELECT
    review_id || '|' || order_id,
    review_id,
    order_id,
    review_score,
    NULL,
    NULL,
    'NO_COMMENT',
    NULL,
    'NO_REASON',
    'NO_REASON',
    NULL,
    NULL,
    'RULE_BASED_NO_COMMENT',
    CURRENT_TIMESTAMP()
FROM OLIST_DWH.STAGING.STG_ORDER_REVIEWS source
WHERE (
    review_comment_message IS NULL
    OR TRIM(review_comment_message) = ''
)
AND NOT EXISTS (
    SELECT 1
    FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION target
    WHERE target.analysis_key =
          source.review_id || '|' || source.order_id
)
"""

cursor.execute(insert_no_comment_query)

connection.commit()

print(
    f"Reviews sans commentaire insérées : {cursor.rowcount}"
)

# ============================================================
# 10. CLOSING
# ============================================================

cursor.close()
connection.close()

print("\nProcessing completed.")