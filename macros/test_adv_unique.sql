/* -----------------------------------------------------

This is an advanced not_null schema test.
It is used the same way the normal not_null schema test is used inside the .yml file
however instead of:
              - not_null
use
              - adv_not_null:

The test has 3 functions:
 - Thresholds (absolute and relative)
 - Date Limits (by day)
 - Row Exclusions (nit picking out bad rows)

Usage Notes:
  Thresholds are calculated after date scoping.
  When testing relative thresholds use values 1 to 100 indicating the % of bad rows expected.
  The error output for threshold fields indicates the number of fails beyond the threshold.
    not the absolute number of fails. (The absolute number can be obtained from a normal test.)
  A single test can use all 3 functions.
  For specifcs on the row exclusions functionality check the exclude_rows_from_test macro


config for .yml file
            - adv_unique:
                model:                          # Taken from the model the test is on
                column_name:                    # Taken from the column the test is on
                event_timestamp_column_name:    # [The date column for date limit tests]
                number_of_days_to_check:        # [The number of days for date limit tests]
                threshold_type:                 # relative / absolute (relative in %)
                threshold_value:                # integer to indicate accepted errors for abs/rel
                column_to_exclude_on:           # if the column has exclusions on a field, enter that column name here

*/ -----------------------------------------------------
{%test adv_unique(
  model,
  column_name,
  event_timestamp_column_name = None,
  number_of_days_to_check = None,
  threshold_type = None,
  threshold_value = 1,
  column_to_exclude_on = None ) %}

/* -----------------------------------------------------
Scope to valid test rows.
*/ -----------------------------------------------------
WITH valid_test_rows AS (
SELECT *
  FROM {{ model }}
 WHERE 1 = 1

   {% if column_to_exclude_on !=  None %} --This will check your test exclusion
    AND {{ exclude_rows_from_test( model.name, column_to_exclude_on ) }}
   {% endif %}

   {% if number_of_days_to_check != None and event_timestamp_column_name != None%}
    AND {{ event_timestamp_column_name }} > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL {{number_of_days_to_check}} DAY)
   {% endif %}
 )
/*-----------------------------------------------------
Set Threshold if applicable.
*/ -----------------------------------------------------

, threshold_limit AS (
SELECT

    {% if threshold_type ==  'relative' %}
      ROUND(COUNT(*) * ({{ threshold_value }} / 100),0) AS max_errors  --find the maximum amount of rows that can fail the test
      FROM valid_test_rows --This allows relative tests to be effective on date range tests

    {% elif threshold_type ==  'absolute' %}
      {{ threshold_value }} AS max_errors  --find the maximum amount of rows that can fail the test

    {% else %} --ELSE
      0 AS max_errors  --find the maximum amount of rows that can fail the test
    {% endif %}
)

/*-----------------------------------------------------
Perform the Test.
*/-----------------------------------------------------

, perform_test AS (

       select
            {{ column_name }}

        from valid_test_rows
        where {{ column_name }} is not null
        group by {{ column_name }}
        having count(*) > 1

)
/*-----------------------------------------------------
Count the Errors.
*/ -----------------------------------------------------
, validation_errors AS (
SELECT
COUNT(*) AS n_errors
FROM perform_test
)
/*-----------------------------------------------------
Check if the number of errors is greater than the threshold.
*/ -----------------------------------------------------
, error_count AS (
SELECT
    CASE WHEN ve.n_errors > tl.max_errors THEN ve.n_errors - tl.max_errors
        WHEN ve.n_errors < tl.max_errors THEN NULL
    ELSE NULL
    END AS result
FROM validation_errors ve
CROSS JOIN threshold_limit tl

)

SELECT * FROM 
error_count
WHERE result IS NOT NULL

   {% endtest %}

