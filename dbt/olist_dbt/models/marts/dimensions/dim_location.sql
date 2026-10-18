WITH source_geolocation AS (

    SELECT *
    FROM {{ ref('stg_geolocation') }}

),

deduplicated_locations AS (

    SELECT DISTINCT
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        geolocation_city,
        geolocation_state

    FROM source_geolocation

),

dim_location AS (

    SELECT
        {{ dbt_utils.generate_surrogate_key([
            'geolocation_zip_code_prefix',
            'geolocation_lat',
            'geolocation_lng'
        ]) }} AS location_key,

        geolocation_zip_code_prefix AS zip_code_prefix,

        geolocation_lat AS latitude,

        geolocation_lng AS longitude,

        geolocation_city AS city,

        geolocation_state AS state

    FROM deduplicated_locations

)

SELECT *
FROM dim_location