use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use lib qw(t/lib);
use DBICTest2;
use Data::Dumper;

my $fixtures;
my $schema;
my $fix_dir= "t/var/fixtures/pk_autoincrement";
my $b1=[];
my $b2=[];

{
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  local *STDERR;
  open(STDERR,">", \$err);
  $schema = DBICTest2->init_schema();
  my $rs = $schema->resultset('Producer');
  my $src = $rs->result_source;
  my $result = $rs->search;

  $fixtures = DBIx::Class::Fixtures
    ->new({
      config_dir => 't/var/configs'
    }  
  );
}

$fixtures->dump({
   config => 'cd_to_producer.json',
   schema => $schema,
   directory => $fix_dir
});

my $rs = $schema->resultset('CD_to_Producer')->search(undef,{order_by=>["cd","producer"]});

while (my $row = $rs->next) { push(@{$b1},[$row->cd,$row->producer->name]) }

my $dbh = $schema->storage->dbh;

foreach my $src ($schema->sources) {
    my $rs = $schema->resultset($src)->result_source;
    $dbh->do("DELETE FROM ".$rs->name);
}

$fixtures->populate({
   config => 'cd_to_producer.json',
   schema => $schema,
   no_deploy=>1,
   use_create=>1,
   directory => $fix_dir
});

$rs = $schema->resultset('CD_to_Producer')->search(undef,{order_by=>["cd","producer"]});

while (my $row = $rs->next) { push(@{$b2},[$row->cd,$row->producer->name]) }

is_deeply($b1,$b2,"Checking consistency after populate");

done_testing;

END {
    rmtree $fix_dir;
}
