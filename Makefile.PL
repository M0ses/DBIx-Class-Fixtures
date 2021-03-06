use inc::Module::Install 0.79;

perl_version '5.006001';
name     'DBIx-Class-Fixtures';
all_from 'lib/DBIx/Class/Fixtures.pm';

requires 'DBIx::Class' => 0.08102;
requires 'Data::Visitor' => 0.15;
requires 'File::Copy::Recursive' => 0.35;
requires 'DateTime' => 0.41;
requires 'DBIx::Class::Schema::Loader' => 0.07000;
requires 'Class::Accessor::Grouped' => 0.06;
requires 'Path::Class' => 0.16;
requires 'Config::Any' => 0.08;
requires 'JSON::Syck' => 0.26;
requires 'Data::Dump::Streamer' => 2.05;
requires 'Hash::Merge' => 0.10;
requires 'Scalar::Util';
requires 'MIME::Base64';
requires 'File::Spec::Functions';
requires 'File::Path';
requires 'Template';

requires 'DateTime::Format::SQLite' => 0.10;
requires 'DateTime::Format::MySQL' => 0;
requires 'DateTime::Format::Pg' => 0;

test_requires 'Test::More';
test_requires 'DBIx::Class::InflateColumn::FS';

tests_recursive();

auto_install;

WriteAll;
