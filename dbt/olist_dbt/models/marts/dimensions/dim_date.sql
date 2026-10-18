WITH date_spine AS (

    SELECT
        DATEADD(
            'day',
            SEQ4(),
            '2016-01-01'::DATE
        ) AS date_day

    FROM TABLE(
        GENERATOR(
            ROWCOUNT => 1100
        )
    )

),

dim_date AS (

    SELECT
        TO_NUMBER(
            TO_CHAR(date_day, 'YYYYMMDD')
        ) AS date_key,

        date_day AS full_date,

        YEAR(date_day) AS year,

        QUARTER(date_day) AS quarter,

        MONTH(date_day) AS month,

        TO_CHAR(date_day, 'MMMM') AS month_name,

        WEEKOFYEAR(date_day) AS week_of_year,

        DAYOFMONTH(date_day) AS day_of_month,

        DAYOFWEEKISO(date_day) AS day_of_week,

        TO_CHAR(date_day, 'DY') AS day_name,

        CASE
            WHEN DAYOFWEEKISO(date_day) IN (6, 7)
                THEN TRUE
            ELSE FALSE
        END AS is_weekend

    FROM date_spine

)

SELECT *
FROM dim_date