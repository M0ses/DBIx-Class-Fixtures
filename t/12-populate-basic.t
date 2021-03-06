#!perl

use DBIx::Class::Fixtures;
use Test::More no_plan;
use lib qw(t/lib);
use DBICTest;
use Path::Class;
use Data::Dumper;

# set up and populate schema
ok(my $schema = DBICTest->init_schema(), 'got schema');
my $config_dir = 't/var/configs';

# do dump
ok(my $fixtures = DBIx::Class::Fixtures->new({ 
    config_dir => $config_dir, 
    debug => 0 
  }), 'object created with correct config dir'
);

foreach my $set ('simple', 'quantity', 'fetch', 'rules') {
  no warnings 'redefine';
  DBICTest->clear_schema($schema);
  DBICTest->populate_schema($schema);
  ok($fixtures->dump({ 
      config => "$set.json", 
      schema => $schema, 
      directory => 't/var/fixtures' 
    }), "$set dump executed okay"
  );
  $fixtures->populate({ 
    ddl => 't/lib/sqlite.sql', 
    connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''], 
    directory => 't/var/fixtures'
  });

  $schema = DBICTest->init_schema( no_deploy => 1);

  my $fixture_dir = dir('t/var/fixtures');
  foreach my $class ($schema->sources) {
    my $source_dir = dir($fixture_dir, lc($class));
    is($schema->resultset($class)->count, 
       (-e $source_dir) ? scalar($source_dir->children) : 0, 
       "correct number of $set " . lc($class)
    );

    next unless (-e $source_dir);

    my $rs = $schema->resultset($class);
    foreach my $row ($rs->all) {
      my $file = file($source_dir, $row->id . '.fix');
      my $HASH1; eval($file->slurp());
      is_deeply(
        $HASH1, 
        {$row->get_columns}, 
        "$set " . lc($class) . " row " . $row->id . " imported okay"
      );
    }
  }
}

# use_create => 1
$schema = DBICTest->init_schema();
$fixtures = DBIx::Class::Fixtures->new({
	config_dir => $config_dir,
	debug => 0
});
ok( $fixtures->dump({
		config => "use_create.json",
		schema => $schema,
		directory => 't/var/fixtures'
	}), "use_create dump executed okay"
);
$schema = DBICTest->init_schema( no_populate => 1 );
$fixtures->populate({
	directory => 't/var/fixtures',
	connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''], 
	schema => $schema,
	no_deploy => 1,
	use_create => 1
});
$schema = DBICTest->init_schema( no_deploy => 1, no_populate => 1 );
is( $schema->resultset( "Artist" )->find({ artistid => 4 })->name, "Test Name", "use_create => 1 ok" );
