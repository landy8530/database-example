select name name_col_plus_show_param,

       decode(type,

              1,

              'boolean',

              2,

              'string',

              3,

              'integer',

              4,

              'file',

              5,

              'number',

              6,

              'big integer',

              'unknown') type,

       display_value value_col_plus_show_param

  from v$parameter

 where upper(name) like upper('%db_file%')

 order by name_col_plus_show_param, rownum;