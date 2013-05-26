use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';

use lib qw(t/lib);
use DBICTest;

my $fixtures;
my $schema;

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

{ 
  my $got='';
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$got);
  local *STDERR;
  open(STDERR,">", \$err);
  $fixtures->dump({
    config => 'skip_tmp_dir.json',
    schema => $schema,
    directory => "t/var/fixtures/skip_tmp_dir"
  }); 
  unlike($got,qr/-~dump~-/,"checking for usage of tmp dir while dump");
};

{
    my $got='';
  my ($out,$err);
    local *STDOUT;
    open(STDOUT,">", \$got);
    local *STDERR;
    open(STDERR,">", \$err);

    $fixtures->populate({
        ddl => 't/lib/sqlite.sql',
        connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''],
        directory => 't/var/fixtures/skip_tmp_dir',
    });
  unlike($got,qr/-~populate~-/,"checking for usage of tmp dir while populate");
} 

ok(-e "t/var/fixtures/skip_tmp_dir/artist/1.fix","checking if first fixture is still there");

done_testing;

END {
    rmtree 't/var/fixtures/skip_tmp_dir/';
}

__END__

open(my $fh, '<', 't/18-extra.t') ||
  die "Can't open the filehandle, test is trash!";

ok my $row = $schema
  ->resultset('Photo')
  ->create({
    photographer=>'john',
    file=>$fh,
  });

close($fh);

my $fixtures = DBIx::Class::Fixtures
  ->new({
    config_dir => 't/var/configs',
    config_attrs => { photo_dir => './t/var/files' },
    debug => 0 });

ok(
  $fixtures->dump({
    config => 'extra.json',
    schema => $schema,
    directory => "t/var/fixtures/photos" }),
  'fetch dump executed okay');

ok my $key = $schema->resultset('Photo')->first->file;

ok -e $key, 'File Created';

ok $schema->resultset('Photo')->delete;

ok ! -e $key, 'File Deleted';

ok(
  $fixtures->populate({
    no_deploy => 1,
    schema => $schema,
    directory => "t/var/fixtures/photos"}),
  'populated');

is $key, $schema->resultset('Photo')->first->file,
  'key is key';

ok -e $key, 'File Restored';

