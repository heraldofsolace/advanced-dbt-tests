/* -----------------------------------------------------
This is the macro that allows the advanced schema tests to access the tbl_test_exclusions 
table.

Arguments:
- model_name: The model you wish to exclude from
- column_name: The column name you wish to exclude on

Output:
A SQL clause that will exclude rows from a table.

Usage:
  Example use case:
  In 2019 a bug allowed a single customer (dim_customer.customer_id =123)
  to be able to sign up without a last name. Then the not_null schema test on
  dim_customer.last_name would always fail on a single row. How Annoying!

  Usage of this macro depends on the configuration of the tbl_test_exclusions
  table schema. It should have the following columns:
    id:               surrogate key for the exclusion table.[N]
    exclusion_value:  unique key of the model that you wish to exclude a row from for testing.[123]
    model_name:       The name of the model that you wish to exclude a row from. [dim_customer]
    column_name:      The name of the column you wish to exclude on. [customer_id]
    owner:            String field to indicate who decided to exclude the row from testing.[your_name]
    description:      String field to explain why this row is special. [Bug back in 2019 that allowed a single customer to sign up with no last name.]

Notes:
The exclusion table can be any table in the database. dbt seed files and Gsheets
work well.
The macro should be placed inside a SQL WHERE clause, either:
- after WHERE
- or after AND
Because of the way get_mode_ref() works, if you choose to create a base table for your
tbl_test_exclusions model you will need to set the schema=none


*/ -----------------------------------------------------
{% macro exclude_rows_from_test(model_name, column_name) %}
CAST({{ column_name }} AS STRING) NOT IN
(
SELECT CAST(exclusion_value AS STRING) AS exclusion_value  -- eg, id
   FROM {{ get_model_ref('tbl_test_exclusions') }} RIRE
  WHERE
  RIRE.model_name =  '{{ model_name }}'
  AND
  RIRE.column_name =  '{{ column_name }}'
)
{% endmacro %}

