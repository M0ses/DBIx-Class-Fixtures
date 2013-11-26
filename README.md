** IMPORTANT **

WARNING: This is *NOT* the official CPAN DBIx::Class::Fixtures modules. It`s just for discussing some of my considerations for usefull enhancements to the official module


** Current modifications **

Feature                     Implemented
skip_tmp_dir                     x
file_per_set                     x
skip_data_visitor                x
dump_indent                      x
substitute                       x
substitute ref                   x
pk_autoincrement                 x
DBIx::Class::Fixture::Compare    x
DBIx::Class::Fixture::Diff       x

additional Configs (diff_config)

$VAR1 = {
      'file_per_set' => 1,
      'sets' => [
                  {
                    'quantity' => 'all',
                    'class' => 'MyCoolClass',
                    'diff_config'=>{
                        # update_strategy:
                        #  update
                        #  update_or_create
                        #  recreate (delete old and insert new records)
                        update_strategy=>'recreate',
                        # pre_sql_statement
                        #   a sql statement execute before doing anything other
                        #   e.g. SELECT INTO OUTFILE
                        pre_sql_statement=>'/* my great statement */',
                        # exclude fields from comparison
                        #   usefull for timestamps, passwords etc.
                        exclude_fields=>['timestamp']
                    }
                  }
                ],
      'might_have' => {
                        'fetch' => 0
                      },
      'belongs_to' => {
                        'fetch' => 0
                      },
      'has_many' => {
                      'fetch' => 0
                    }
};

