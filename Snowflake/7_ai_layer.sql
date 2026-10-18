CREATE TABLE IF NOT EXISTS OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION (

    analysis_key VARCHAR,

    review_id VARCHAR,

    order_id VARCHAR,

    sentiment_label VARCHAR,

    sentiment_confidence FLOAT,

    main_cause VARCHAR,

    cause_labels VARCHAR,

    satisfaction_score INTEGER,

    evidence_text VARCHAR,

    model_name VARCHAR,

    analysis_timestamp TIMESTAMP_NTZ

);

SELECT *
FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
ORDER BY analysis_timestamp DESC;

SELECT
    sentiment_label,
    main_cause,
    COUNT(*) AS number_of_reviews
FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
GROUP BY
    sentiment_label,
    main_cause
ORDER BY number_of_reviews DESC;

ALTER TABLE OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
RENAME COLUMN satisfaction_score TO review_score;

ALTER TABLE OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
ADD COLUMN comment_original VARCHAR;

ALTER TABLE OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
ADD COLUMN comment_translated_en VARCHAR;

ALTER TABLE OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
ADD COLUMN evidence_text_en VARCHAR;

TRUNCATE TABLE OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION;

SELECT count(*)
FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION;

SELECT 
    delivered_on_time,
    COUNT(*) AS nombre_lignes,
    COUNT(DISTINCT order_id) AS nombre_commandes
FROM OLIST_DWH.MARTS.FACT_SALES
GROUP BY delivered_on_time;

SELECT 
    delivery_delay_days,
    delivered_on_time,
    COUNT(*) AS total
FROM OLIST_DWH.MARTS.FACT_SALES
GROUP BY delivery_delay_days, delivered_on_time
ORDER BY delivery_delay_days ASC
LIMIT 20;

SELECT 
    order_id,
    COUNT(DISTINCT delivered_on_time) AS nb_statuts_differents
FROM OLIST_DWH.MARTS.FACT_SALES
GROUP BY order_id
HAVING COUNT(DISTINCT delivered_on_time) > 1;