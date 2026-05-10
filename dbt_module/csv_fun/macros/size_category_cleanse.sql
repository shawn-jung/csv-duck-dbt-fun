{% macro cleanse_size(column) -%}
    {#- regex is overkill, this is enough for the club shirts -#}
    case
        when upper(trim({{ column }})) in ('XS')                          then 'XS'
        when upper(trim({{ column }})) like '%EXTRA%SMALL%'               then 'XS'
        when upper(trim({{ column }})) like '%X_SMALL%'                   then 'XS'

        when upper(trim({{ column }})) in ('S', 'SM', 'SMALL')            then 'S'

        when upper(trim({{ column }})) in ('M', 'MED', 'MEDIUM')          then 'M'

        when upper(trim({{ column }})) in ('L', 'LG', 'LARGE')            then 'L'

        when upper(trim({{ column }})) in ('XL')                          then 'XL'
        when upper(trim({{ column }})) like '%EXTRA%LARGE%'               then 'XL'
        when upper(trim({{ column }})) like '%X_LARGE%'                   then 'XL'
        when upper(trim({{ column }})) like 'XLARGE'                      then 'XL'

        when upper(trim({{ column }})) in ('2XL', 'XXL', '2X', 'DOUBLE XL') then '2XL'
        when upper(trim({{ column }})) like '2X%LARGE%'                   then '2XL'
        when upper(trim({{ column }})) like 'XX%LARGE%'                   then '2XL'

        else upper(trim({{ column }}))
    end
{% endmacro -%}
