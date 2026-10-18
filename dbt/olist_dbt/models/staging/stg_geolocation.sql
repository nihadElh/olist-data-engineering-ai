WITH source_geolocation AS (

    SELECT *
    FROM {{ source('raw_olist', 'RAW_GEOLOCATION') }}

),

cleaned_geolocation AS (

    SELECT
            geolocation_zip_code_prefix AS geolocation_zip_code_prefix,
            geolocation_lat AS geolocation_lat,
            geolocation_lng AS geolocation_lng,

        INITCAP(
            TRIM(geolocation_city)
        ) AS geolocation_city,

        UPPER(
            TRIM(geolocation_state)
        ) AS geolocation_state

    FROM source_geolocation

)

SELECT *
FROM cleaned_geolocation