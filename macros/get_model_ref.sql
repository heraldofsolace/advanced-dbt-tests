/*
Purpose:
to provide an alternative for {{ ref('model_name') }}
that will allow dbt to compile:
- when using a diabled model
- when there is a {{ ref('model_name') }} inside a conditional block.

Arguments:
    model_name: the model name that might be disabled but needs to be referenced

Output:
project_id.dataset_name.table_name

Notes:
This doesn't include any custom schemas.
*/

{% macro get_model_ref(model_name) %}
`{{target.project}}.{{target.schema}}.{{model_name}}`
{% endmacro %}
