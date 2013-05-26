use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use lib qw(t/lib);
use DBICTest;

my $fixtures;
my $schema;
my $fix_dir= "t/var/fixtures/file_per_set";

{
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  local *STDERR;
  open(STDERR,">", \$err);

  ok($schema = DBICTest->init_schema(), 'got schema');
  $fixtures = DBIx::Class::Fixtures
    ->new({
      config_dir => 't/var/configs',
      debug => 9 }
  );
}

  my $expected = { artist => {
           1     => {
                      artistid => 1,
                      name     => 'Caterwauler McCrae'
                    },
           2     => {
                      artistid => 2,
                      name     => 'Random Boy Band'
                    },
           3     => {
                      artistid => 3,
                      name     => 'We Are Goth'
                    },
           4     => {
                      artistid => 4,
                      name     => ''
                    },
           32948 => {
                      artistid => 32948,
                      name     => 'Big PK'
                    }
         } };

{
  my $got='';

  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$got);
  $fixtures->dump({
    config => 'file_per_set.json',
    schema => $schema,
    directory => $fix_dir
  });
  my $dsfn = $fix_dir."/data_set.fix"; # dsfn = data set file name
  ok(-e $dsfn,"wrote to right file");
  my $infile = Path::Class::file->new($dsfn);
  my $fc = $infile->slurp;
  my $HASH1;
  eval($fc);
  is_deeply($HASH1,$expected,"after dump - checking data in data_set.fix");
};

{
  my $got={};
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  $fixtures->populate({
        ddl => 't/lib/sqlite.sql',
        connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''],
        directory => $fix_dir
   });
  my $result = $schema->resultset('Artist')->search(undef,{order_by=>'artistid'});
  # create expected hash
  while (my $record = $result->next) {
        my $tmp = {};
        foreach my $col ($record->columns) {
            $tmp->{$col} = $record->$col;    
        }    
        $got->{artist}->{$record->artistid}=$tmp;
  }        
  is_deeply($got,$expected,'after populate - checking data in database');
}

done_testing;

END {
    rmtree $fix_dir;
}
