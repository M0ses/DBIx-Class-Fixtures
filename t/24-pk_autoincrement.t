use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use lib qw(t/lib);
use DBICTest;
use Data::Dumper;

my $fixtures;
my $schema;
my $fix_dir= "t/var/fixtures/pk_autoincrement";

my $expected = { artist => {
                1 => {
                       artistid => undef,
                       name     => 'Caterwauler McCrae'
                     },
                2 => {
                       artistid => undef,
                       name     => 'Random Boy Band'
                     },
                3 => {
                       artistid => undef,
                       name     => 'We Are Goth'
                     },
                4 => {
                       artistid => undef,
                       name     => ''
                     },
                5 => {
                       artistid => undef,
                       name     => 'Big PK'
                     }
              } };
# initialize
{
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  local *STDERR;
  open(STDERR,">", \$err);
  $schema = DBICTest->init_schema();
  $fixtures = DBIx::Class::Fixtures
    ->new({
      config_dir => 't/var/configs'
    }  
  );
}


  $fixtures->dump({
    config => 'pk_autoincrement.json',
    schema => $schema,
    directory => $fix_dir
  });
  my $dsfn = $fix_dir."/data_set.fix"; # dsfn = data set file name
  my $infile = Path::Class::file->new($dsfn);
  my $HASH1;
  eval($infile->slurp);
  my $got = $HASH1;
  is_deeply($got,$expected,'checking pk_autoincrement');

{
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  local *STDERR;
  open(STDERR,">", \$err);
  $schema = DBICTest->init_schema(no_populate=>1);
}

$fixtures->populate({
    ddl => 't/lib/sqlite.sql',
    connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''],
    directory => $fix_dir
});

my $got = $schema->resultset('Artist')->find({name=>'Big PK'})->artistid;

is($got,5,"checking id for 'Big PK' after dump/populate");

done_testing;

END {
    rmtree $fix_dir;
}
