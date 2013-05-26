use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use lib qw(t/lib);
use DBICTest;
use Data::Dumper;

my $fixtures;
my $schema;
my $fix_dir= "t/var/fixtures/substitute";

my $expected = q/$HASH1 = {
           cd      => 1,
           last_updated_on
                   => \do { my $v = 'NOW()' },
           position
                   => 2,
           title   => 'Apiary',
           trackid => undef
         };
/;

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
    config => 'substitute.json',
    schema => $schema,
    directory => $fix_dir
  });
  my $dsfn = $fix_dir."/track/17.fix"; # dsfn = data set file name
  my $infile = Path::Class::file->new($dsfn);
  my $got = $infile->slurp;
  is($got,$expected,'checking substitution');

done_testing;

END {
    rmtree $fix_dir;
}
