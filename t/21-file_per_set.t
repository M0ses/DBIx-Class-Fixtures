use DBIx::Class::Fixtures;
use Test::More;
use File::Path 'rmtree';
use Path::Class::File;
use Path::Class::Dir;
use lib qw(t/lib);
use DBICTest;
use strict;
use warnings;

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

my $expected;
{
    local $/;
    undef $/;
    my $in = <DATA>;
    eval "$in";
}

{

  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
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
  is_deeply($HASH1,$expected->[0],"after dump - checking data in data_set.fix");
};

{
  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$out);
  $fixtures->populate({
        ddl => 't/lib/sqlite.sql',
        connection_details => ['dbi:SQLite:t/var/DBIxClass.db', '', ''],
        directory => $fix_dir
   });
  my $result = $schema->resultset('CD')->search(undef,{order_by=>'cdid'});
  # create expected hash
  my $got = resultToRef($result);
  is_deeply($got,$expected->[1],'after populate - checking data in database');
}

{
  rmtree $fix_dir;      
  my $got='';

  my ($out,$err);
  local *STDOUT;
  open(STDOUT,">", \$got);
  $fixtures->dump({
    config => 'file_per_set_wrong.json',
    schema => $schema,
    debug=>9,
    directory => $fix_dir
  });

  my $dir = Path::Class::Dir->new($fix_dir,'artist');
  no warnings 'numeric';
  my  @files = sort { $a > $b } map { $_->basename } $dir->children;
  use Data::Dumper;
  print Dumper(\@files);

  my $dsfn = $fix_dir."/data_set.fix"; # dsfn = data set file name

  is_deeply(\@files,[ '1.fix', '2.fix', '3.fix' ],"splitted files");
};
done_testing;

END {
#    rmtree $fix_dir;
}

sub resultToRef {
  my $result = shift;
  my @rv=();
  my @inList = ();
  if (ref($result) eq 'DBIx::Class::ResultSet' ) {
          while (my $record = $result->next) {
            push ( @inList , $record );
          }
  } else {
    @inList = ($result);
  }
  foreach my $record (@inList) {
        my $tmp = {};
        foreach my $col ($record->columns) {
            if ( ref($record->$col) ) {
                $tmp->{$col} = resultToRef($record->$col);
            } else {
                $tmp->{$col} = $record->$col;
            }
        }    
        push(@rv,$tmp);
  }        
  
  return ( @rv == 1 ) ? $rv[0] : \@rv;
}
__DATA__
$expected->[0] = {
           artist  => {
                        1 => {
                               artistid => 1,
                               name     => 'Caterwauler McCrae'
                             },
                        2 => {
                               artistid => 2,
                               name     => 'Random Boy Band'
                             },
                        3 => {
                               artistid => 3,
                               name     => 'We Are Goth'
                             }
                      },
           cd      => {
                        1 => {
                               artist => 1,
                               cdid   => 1,
                               title  => 'Spoonful of bees',
                               year   => 1999
                             },
                        2 => {
                               artist => 1,
                               cdid   => 2,
                               title  => 'Forkful of bees',
                               year   => 2001
                             },
                        3 => {
                               artist => 1,
                               cdid   => 3,
                               title  => 'Caterwaulin\' Blues',
                               year   => 1997
                             },
                        4 => {
                               artist => 2,
                               cdid   => 4,
                               title  => 'Generic Manufactured Singles',
                               year   => 2001
                             },
                        5 => {
                               artist => 2,
                               cdid   => 5,
                               title  => 'We like girls and stuff',
                               year   => 2003
                             },
                        6 => {
                               artist => 3,
                               cdid   => 6,
                               title  => 'Come Be Depressed With Us',
                               year   => 1998
                             }
                      },
           cd_to_producer
                   => {
                        "1-1" => {
                                   cd       => 1,
                                   producer => 1
                                 },
                        "1-2" => {
                                   cd       => 1,
                                   producer => 2
                                 },
                        "1-3" => {
                                   cd       => 1,
                                   producer => 3
                                 },
                        "2-1" => {
                                   cd       => 2,
                                   producer => 1
                                 },
                        "2-2" => {
                                   cd       => 2,
                                   producer => 2
                                 },
                        "3-3" => {
                                   cd       => 3,
                                   producer => 3
                                 }
                      },
           producer
                   => {
                        1 => {
                               name       => 'Matt S Trout',
                               producerid => 1
                             },
                        2 => {
                               name       => 'Bob The Builder',
                               producerid => 2
                             },
                        3 => {
                               name       => 'Fred The Phenotype',
                               producerid => 3
                             }
                      },
           tags    => {
                        1 => {
                               cd    => 1,
                               tag   => 'Blue',
                               tagid => 1
                             },
                        2 => {
                               cd    => 2,
                               tag   => 'Blue',
                               tagid => 2
                             },
                        3 => {
                               cd    => 3,
                               tag   => 'Blue',
                               tagid => 3
                             },
                        4 => {
                               cd    => 5,
                               tag   => 'Blue',
                               tagid => 4
                             },
                        5 => {
                               cd    => 2,
                               tag   => 'Cheesy',
                               tagid => 5
                             },
                        6 => {
                               cd    => 4,
                               tag   => 'Cheesy',
                               tagid => 6
                             },
                        7 => {
                               cd    => 5,
                               tag   => 'Cheesy',
                               tagid => 7
                             },
                        8 => {
                               cd    => 2,
                               tag   => 'Shiny',
                               tagid => 8
                             },
                        9 => {
                               cd    => 4,
                               tag   => 'Shiny',
                               tagid => 9
                             }
                      },
           track   => {
                        4  => {
                                cd      => 2,
                                last_updated_on
                                        => undef,
                                position
                                        => 1,
                                title   => 'Stung with Success',
                                trackid => 4
                              },
                        5  => {
                                cd      => 2,
                                last_updated_on
                                        => undef,
                                position
                                        => 2,
                                title   => 'Stripy',
                                trackid => 5
                              },
                        6  => {
                                cd      => 2,
                                last_updated_on
                                        => undef,
                                position
                                        => 3,
                                title   => 'Sticky Honey',
                                trackid => 6
                              },
                        7  => {
                                cd      => 3,
                                last_updated_on
                                        => undef,
                                position
                                        => 1,
                                title   => 'Yowlin',
                                trackid => 7
                              },
                        8  => {
                                cd      => 3,
                                last_updated_on
                                        => undef,
                                position
                                        => 2,
                                title   => 'Howlin',
                                trackid => 8
                              },
                        9  => {
                                cd      => 3,
                                last_updated_on
                                        => '2007-10-20 00:00:00',
                                position
                                        => 3,
                                title   => 'Fowlin',
                                trackid => 9
                              },
                        10 => {
                                cd      => 4,
                                last_updated_on
                                        => undef,
                                position
                                        => 1,
                                title   => 'Boring Name',
                                trackid => 10
                              },
                        11 => {
                                cd      => 4,
                                last_updated_on
                                        => undef,
                                position
                                        => 2,
                                title   => 'Boring Song',
                                trackid => 11
                              },
                        12 => {
                                cd      => 4,
                                last_updated_on
                                        => undef,
                                position
                                        => 3,
                                title   => 'No More Ideas',
                                trackid => 12
                              },
                        13 => {
                                cd      => 5,
                                last_updated_on
                                        => undef,
                                position
                                        => 1,
                                title   => 'Sad',
                                trackid => 13
                              },
                        14 => {
                                cd      => 5,
                                last_updated_on
                                        => undef,
                                position
                                        => 2,
                                title   => 'Under The Weather',
                                trackid => 14
                              },
                        15 => {
                                cd      => 5,
                                last_updated_on
                                        => undef,
                                position
                                        => 3,
                                title   => 'Suicidal',
                                trackid => 15
                              },
                        16 => {
                                cd      => 1,
                                last_updated_on
                                        => undef,
                                position
                                        => 1,
                                title   => 'The Bees Knees',
                                trackid => 16
                              },
                        17 => {
                                cd      => 1,
                                last_updated_on
                                        => undef,
                                position
                                        => 2,
                                title   => 'Apiary',
                                trackid => 17
                              },
                        18 => {
                                cd      => 1,
                                last_updated_on
                                        => undef,
                                position
                                        => 3,
                                title   => 'Beehind You',
                                trackid => 18
                              }
                      }
         };
$expected->[1] = [
          {
            'artist' => {
                          'artistid' => 1,
                          'name' => 'Caterwauler McCrae'
                        },
            'cdid' => 1,
            'title' => 'Spoonful of bees',
            'year' => '1999'
          },
          {
            'artist' => {
                          'artistid' => 1,
                          'name' => 'Caterwauler McCrae'
                        },
            'cdid' => 2,
            'title' => 'Forkful of bees',
            'year' => '2001'
          },
          {
            'artist' => {
                          'artistid' => 1,
                          'name' => 'Caterwauler McCrae'
                        },
            'cdid' => 3,
            'title' => 'Caterwaulin\' Blues',
            'year' => '1997'
          },
          {
            'artist' => {
                          'artistid' => 2,
                          'name' => 'Random Boy Band'
                        },
            'cdid' => 4,
            'title' => 'Generic Manufactured Singles',
            'year' => '2001'
          },
          {
            'artist' => {
                          'artistid' => 2,
                          'name' => 'Random Boy Band'
                        },
            'cdid' => 5,
            'title' => 'We like girls and stuff',
            'year' => '2003'
          },
          {
            'artist' => {
                          'artistid' => 3,
                          'name' => 'We Are Goth'
                        },
            'cdid' => 6,
            'title' => 'Come Be Depressed With Us',
            'year' => '1998'
          }
        ];

