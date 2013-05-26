use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use lib qw(t/lib);
use DBICTest;

my $fixtures;
my $schema;
my $fix_dir= "t/var/fixtures/file_per_set";

my $expected = q/$HASH1={artist=>{1=>{artistid=>1,name=>'Caterwauler McCrae'},2=>{artistid=>2,name=>'Random Boy Band'},3=>{artistid=>3,name=>'We Are Goth'},4=>{artistid=>4,name=>''},32948=>{artistid=>32948,name=>'Big PK'}}};
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


# tests
{

  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  $fixtures->dump({
    config => 'dump_indent.json',
    schema => $schema,
    directory => $fix_dir
  });

  my $dsfn = $fix_dir."/data_set.fix"; # dsfn = data set file name
  ok(-e $dsfn,"wrote to right file");
  my $infile = Path::Class::file->new($dsfn);
  my $got = $infile->slurp;
  is($got,$expected,'checking non indented file');
};

done_testing;

END {
    rmtree $fix_dir;
}
