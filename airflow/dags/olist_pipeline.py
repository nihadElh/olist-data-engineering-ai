from datetime import timedelta
import pendulum

from airflow.sdk import dag
from airflow.providers.standard.operators.bash import BashOperator
from airflow.providers.snowflake.operators.snowflake import SnowflakeSqlApiOperator


# ============================================================
# CONFIGURATION
# ============================================================

SNOWFLAKE_CONN_ID = "olist_snowflake"

DBT_PROJECT_DIR = "/opt/airflow/olist_project/dbt/olist_dbt"
AI_SCRIPT = "/opt/airflow/olist_project/ai_review_analysis.py"

# ============================================================
# DAG
# ============================================================

@dag(
    dag_id="olist_pipeline",

    schedule=None,

    start_date=pendulum.datetime(
        2026,
        9,
        25,
        tz="UTC",
    ),

    catchup=False,

    default_args={
        "retries": 2,
        "retry_delay": timedelta(minutes=2),
    },

    tags=[
        "olist",
        "data-engineering",
        "snowflake",
        "dbt",
        "ai",
    ],
)
def olist_pipeline():

    # ========================================================
    # 1. S3 TO SNOWFLAKE (COPY INTO)
    # ========================================================

    s3_to_snowflake_ingestion = SnowflakeSqlApiOperator(
        task_id="s3_to_snowflake_ingestion",

        snowflake_conn_id=SNOWFLAKE_CONN_ID,

        sql="""
        USE ROLE ACCOUNTADMIN;
        USE DATABASE OLIST_DWH;
        USE SCHEMA RAW;

        COPY INTO OLIST_DWH.RAW.RAW_CUSTOMERS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_customers_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'ABORT_STATEMENT';

        COPY INTO OLIST_DWH.RAW.RAW_GEOLOCATION
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_geolocation_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_ORDERS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_orders_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_ORDER_ITEMS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_order_items_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_ORDER_PAYMENTS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_order_payments_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_ORDER_REVIEWS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_order_reviews_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_PRODUCTS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_products_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_PRODUCT_CATEGORY_TRANSLATION
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/product_category_name_translation.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';

        COPY INTO OLIST_DWH.RAW.RAW_SELLERS
        FROM @OLIST_DWH.RAW.OLIST_S3_STAGE/olist_sellers_dataset.csv
        FILE_FORMAT = (FORMAT_NAME = OLIST_DWH.RAW.FF_OLIST_CSV)
        ON_ERROR = 'CONTINUE';
        """,

        statement_count=9,

        deferrable=False,
    )


    # ========================================================
    # 2. VALIDATE RAW DATA
    # ========================================================

    validate_raw_data = SnowflakeSqlApiOperator(
        task_id="validate_raw_data",

        snowflake_conn_id=SNOWFLAKE_CONN_ID,

        sql="""
        SELECT
            CASE
                WHEN COUNT(*) > 0 THEN TRUE
                ELSE FALSE
            END AS raw_data_available
        FROM OLIST_DWH.RAW.RAW_ORDERS;
        """,

        statement_count=1,

        deferrable=False,
    )


    # ========================================================
    # 3. DBT STAGING
    # ========================================================

    dbt_staging = BashOperator(
        task_id="dbt_staging",

        bash_command=f"""
        set -e

        cd {DBT_PROJECT_DIR}

        dbt run --select staging
        """,
    )


    # ========================================================
    # 4. DBT MARTS
    # ========================================================

    dbt_marts = BashOperator(
        task_id="dbt_marts",

        bash_command=f"""
        set -e

        cd {DBT_PROJECT_DIR}

        dbt run --select marts
        """,
    )

    dbt_snapshots= BashOperator(
        task_id="dbt_snapshots",
        bash_command=f"""
        set -e
        cd {DBT_PROJECT_DIR}
        dbt snapshot
        """,
    )


    # ========================================================
    # 5. AI REVIEW ANALYSIS
    # ========================================================

    analyze_reviews_ai = BashOperator(
        task_id="analyze_reviews_ai",

        bash_command=f"""
        set -e

        python {AI_SCRIPT}
        """,

        execution_timeout=timedelta(hours=6),
    )


    # ========================================================
    # 6. DATA QUALITY CHECKS
    # ========================================================

    quality_checks = SnowflakeSqlApiOperator(
        task_id="quality_checks",

        snowflake_conn_id=SNOWFLAKE_CONN_ID,

        sql="""

        -- ==================================================
        -- CHECK 1
        -- FACT_REVIEWS must not contain duplicate
        -- review_id + order_id
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) = 0 THEN TRUE
                ELSE FALSE
            END AS no_duplicate_reviews
        FROM (
            SELECT
                review_id,
                order_id
            FROM OLIST_DWH.MARTS.FACT_REVIEWS
            GROUP BY
                review_id,
                order_id
            HAVING COUNT(*) > 1
        );


        -- ==================================================
        -- CHECK 2
        -- AI table must not contain duplicate
        -- review_id + order_id
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) = 0 THEN TRUE
                ELSE FALSE
            END AS no_duplicate_ai_reviews
        FROM (
            SELECT
                review_id,
                order_id
            FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
            GROUP BY
                review_id,
                order_id
            HAVING COUNT(*) > 1
        );


        -- ==================================================
        -- CHECK 3
        -- review_score must be between 1 and 5
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) = 0 THEN TRUE
                ELSE FALSE
            END AS valid_review_scores
        FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
        WHERE review_score IS NOT NULL
          AND (
                review_score < 1
                OR review_score > 5
              );


        -- ==================================================
        -- CHECK 4
        -- sentiment must contain an allowed value
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) = 0 THEN TRUE
                ELSE FALSE
            END AS valid_sentiments
        FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
        WHERE sentiment_label NOT IN (
            'POSITIVE',
            'NEGATIVE',
            'NEUTRAL',
            'MIXED',
            'NO_COMMENT'
        );


        -- ==================================================
        -- CHECK 5
        -- main_cause must contain an allowed value
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) = 0 THEN TRUE
                ELSE FALSE
            END AS valid_causes
        FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION
        WHERE main_cause NOT IN (
            'PRODUCT_QUALITY',
            'PRODUCT_DESCRIPTION',
            'PRODUCT_SIZE',
            'DELIVERY_DELAY',
            'DELIVERY_SPEED',
            'DAMAGED_PACKAGE',
            'PACKAGING',
            'PRICE_VALUE',
            'PAYMENT',
            'CUSTOMER_SERVICE',
            'ORDER_ACCURACY',
            'PRODUCT_SATISFACTION',
            'OTHER',
            'NO_REASON'
        );


        -- ==================================================
        -- CHECK 6
        -- AI analysis must preserve source review_score
        -- ==================================================

        SELECT
            CASE
                WHEN COUNT(*) > 0 THEN FALSE
                ELSE TRUE
            END AS review_score_consistency
        FROM OLIST_DWH.MARTS.FACT_REVIEW_SATISFACTION f
        JOIN OLIST_DWH.STAGING.STG_ORDER_REVIEWS r
            ON f.review_id = r.review_id
           AND f.order_id = r.order_id
        WHERE f.review_score <> r.review_score;

        """,

        statement_count=6,

        deferrable=False,
    )


    

    # ========================================================
    # 7. PIPELINE END
    # ========================================================

    pipeline_end = SnowflakeSqlApiOperator(
        task_id="pipeline_end",

        snowflake_conn_id=SNOWFLAKE_CONN_ID,

        sql="""
        SELECT
            'OLIST_PIPELINE_COMPLETED' AS pipeline_status,
            CURRENT_TIMESTAMP() AS completed_at;
        """,

        statement_count=1,

        deferrable=False,
    )


    # ========================================================
    # DEPENDENCIES
    # ========================================================

    (
        s3_to_snowflake_ingestion
        >> validate_raw_data
        >> dbt_staging
        >> dbt_snapshots
        >> dbt_marts
        >> analyze_reviews_ai
        >> quality_checks
        >> pipeline_end
    )


# ============================================================
# REGISTER DAG
# ============================================================

olist_pipeline()