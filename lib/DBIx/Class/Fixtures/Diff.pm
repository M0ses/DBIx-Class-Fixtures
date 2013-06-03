package DBIx::Class::Fixtures::Diff;

use Moose;
use Path::Class::File;
use Data::Dumper;

has target_dir          => (is=>'rw',isa=>'Str',default=>'./share');


has schema              => (is=>'rw',trigger=>\&_set_table2class_map);
has _table2class_map    => (is=>'rw',isa=>"HashRef",default=>sub { {} });

has from_version        => (is=>'rw',isa=>'Str');
has to_version          => (is=>'rw',isa=>'Str');

has from_content        => (is=>'rw',isa=>'Str');
has to_content          => (is=>'rw',isa=>'Str');

# has from_file        => (is=>'rw',isa=>'Str');
# has to_file          => (is=>'rw',isa=>'Str');

has from_struct         => (is=>'rw',isa=>'Str');
has to_struct           => (is=>'rw',isa=>'Str');
has __diff_struct         => (is=>'rw',isa=>'HashRef'     , default => sub { {} });
has named_sets          => (is=>'rw',isa=>'ArrayRef'    , default=>sub { [] });

has databases           => (is=>'rw',isa=>'ArrayRef'    , default=>sub { [] });



sub _set_table2class_map {
    my ( $self, $schema, $old_schema ) = @_;
    
    my $map = $self->_table2class_map();
    %{$map} = ();

    map { $map->{$schema->source($_)->name} = $_ } $schema->sources;

}

has create_scripts_callback =>(
    is=>'rw',
    isa=>'CodeRef',
    default=> sub {
        return 
        ## callback function
        sub {
            my ($self)=@_;
            my $direction = "upgrade";
            my $schema = $self->schema;

            $direction = "downgrade" if ($self->from_version > $self->to_version );

            foreach my $db (@{$self->databases}) {
                my $script_file = Path::Class::File->new(
                    $self->target_dir,
                    'migrations',
                    $db,
                    $direction,
                    $self->from_version."-".$self->to_version,
                    "099-auto-fixtures-migration.pl"
                );

                my $template = 
'#!/usr/bin/perl
#
use strict;
use warnings;

use DBIx::Class::Migration::RunScript;


use '.$schema.';

my $routines = {
    "delete"    =>\&delete,
    "insert"    =>\&insert,
    "update"    =>\&update,
};

sub insert {
    my $self = shift;
    my $class = shift;
    my $schema = '.$schema.'->connect({dbh_maker=>sub { return $self->dbh}});
    foreach my $pk (keys(%%{$_[0]})) {
        print "  - inserting $pk\n";
        my $rs = $schema->resultset($class);
        $rs->find_or_create($_[0]->{$pk});
     }
}

sub delete  {

    my $self = shift;
    my $class = shift;
    my $schema = '.$schema.'->connect({dbh_maker=>sub { return $self->dbh}});

    foreach my $pk (keys(%%{$_[0]})) {
        print "  - deleting $pk\n";
        my $rs = $schema->resultset($class)->find($_[0]->{$pk});
        $rs->delete;
     }

}
sub update  {

    my $self = shift;
    my $class = shift;
    my $schema = '.$schema.'->connect({dbh_maker=>sub { return $self->dbh}});

    foreach my $pk (keys(%%{$_[0]})) {
        print "  - updating $pk\n";
        my $rs = $schema->resultset($class)->find($_[0]->{$pk});

        if (! $rs ) {
            print "   - Not found\n";
        } else {
            $rs->update($_[0]->{$pk});
        }

     }
}

migrate {
    my $self = shift;
    my %s

    foreach my $set_name (keys(%%{$VAR1})) {
        print "- use Set $set_name";
        foreach my $class (keys(%%{$VAR1->{$set_name}})) {
            foreach my $meth (sort(keys(%%{$VAR1->{$set_name}->{$class}}))) {
                $routines->{$meth}->($self,$class,$VAR1->{$set_name}->{$class}->{$meth});
            }        
        }
    }        

}

';
        -d $script_file->parent->stringify || $script_file->parent->mkpath;
        $script_file->spew(
            sprintf(
                $template,
                Dumper($self->__diff_struct)
            )    
        );
    }
    
} # end code ref
    } # end default sub
);

sub create_migration_scripts {
    my ($self)=@_;

    my $codeRef = $self->create_scripts_callback;

    $codeRef->(@_);
}    

sub diff {
    my $self = shift;

    my $fileStore={};
    my $structs={};
    my $map = $self->_table2class_map;

    # TODO: Refactor - function would be cool
    foreach my $set_name (@{$self->named_sets}) { 
        my $HASH1;    
        $fileStore->{from}->{file} = Path::Class::File->new($self->target_dir,'fixtures',$self->from_version,$set_name,"data_set.fix"); 
        $fileStore->{to}->{file} = Path::Class::File->new($self->target_dir,'fixtures',$self->to_version,$set_name,"data_set.fix"); 
        $fileStore->{from}->{file}->openr;
        $fileStore->{to}->{file}->openr;
        $fileStore->{from}->{text} = $fileStore->{from}->{file}->slurp;
        $fileStore->{to}->{text} = $fileStore->{to}->{file}->slurp;
        eval "$fileStore->{from}->{text}";
        $fileStore->{from}->{struct} = $HASH1;
        eval "$fileStore->{to}->{text}";
        $fileStore->{to}->{struct} = $HASH1;
        
        my $cmp = DBIx::Class::Fixtures::Compare->new(
            from=>$fileStore->{from}->{struct},
            to=>$fileStore->{to}->{struct}
        );
        my $raw_struct = $cmp->compare;
        foreach my $old_key (keys%{$raw_struct}) {
            my $new_key = $map->{$old_key};
            $raw_struct->{$new_key} = $raw_struct->{$old_key};
            delete $raw_struct->{$old_key};
        }
        $structs->{$set_name} = $raw_struct;
    }    

    $self->__diff_struct($structs);
    return $structs;
}        

1;
