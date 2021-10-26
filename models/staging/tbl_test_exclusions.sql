
{{
  config(
    materialized='table',
    schema=none
  )
}}
/* -----------------------------------------------------

Scope: Identifying data for rows in models that we wish to exclude from certain tests because
they will cause the test to constantly fail.

Grain: id(surrogate key from source table which is a gsheet.)

Purpose: to create a base model for the test exclusion dataset.

Config:
This model has to be a table because the source data is a a gsheet which has strange errors
when it is repeatedly queried.

The schema must be set to none because it is referred to using the get_model_ref macro
which is designed to get around a strange issue with using refs in conditional blocks.
https://github.com/dbt-labs/dbt/issues/1077.


Notes:

*/ -----------------------------------------------------

SELECT rite.id,
       rite.exclusion_value,
       rite.model_name,
       rite.column_name,
       rite.owner,
       rite.description
  FROM {{ ref('raw_test_exclusions') }} rite
 WHERE rite.id IS NOT NULL
   AND rite.exclusion_value IS NOT NULL
   AND rite.model_name IS NOT NULL
   AND rite.column_name IS NOT NULL