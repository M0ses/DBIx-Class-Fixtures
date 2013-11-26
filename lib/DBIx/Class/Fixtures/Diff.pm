package DBIx::Class::Fixtures::Diff;

use Moose;
use Path::Class::File;
use Data::Dumper;
use Template;
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

                    my $output = '';
                    my $template = Template->new();
                    my $vars={
                        schema=>$schema,
                        VAR1=>Dumper($self->__diff_struct)
                    };
                    $template->process(\*DATA, $vars,\$output) || die $template->error(), "\n";
                    -d $script_file->parent->stringify || $script_file->parent->mkpath;
                    $script_file->spew($output);
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
        my $HASH1=undef;
        my $VAR1=undef;
        $fileStore->{from}->{file} = Path::Class::File->new($self->target_dir,'fixtures',$self->from_version,$set_name,"data_set.fix");
        $fileStore->{to}->{file} = Path::Class::File->new($self->target_dir,'fixtures',$self->to_version,$set_name,"data_set.fix");
        $fileStore->{config}->{file} = Path::Class::File->new($self->target_dir,'fixtures',$self->to_version,$set_name,"_config_set");

        $fileStore->{from}->{text} = $fileStore->{from}->{file}->slurp;
        $fileStore->{to}->{text} = $fileStore->{to}->{file}->slurp;
        $fileStore->{config}->{text} = $fileStore->{config}->{file}->slurp;
        eval "$fileStore->{from}->{text}";
        $fileStore->{from}->{struct} = $HASH1;
        eval "$fileStore->{to}->{text}";
        $fileStore->{to}->{struct} = $HASH1;
        eval "$fileStore->{config}->{text}";
        $fileStore->{config}->{struct} = $VAR1;


        my $cmp = DBIx::Class::Fixtures::Compare->new(
            from=>$fileStore->{from}->{struct},
            to=>$fileStore->{to}->{struct},
            config=>$self->_prepare_config($fileStore->{config}->{struct})
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

sub _prepare_config {
    my $self = shift;
    my $config = shift;
    my $map = $self->_table2class_map;
    my $rmap={};
    my $rv={};
    while (my ($k,$v) = each(%$map) ) {  $rmap->{$v} = $k }

    foreach my $set (@{$config->{sets}}) {
        $rv->{
           $rmap->{$set->{class}}
        } = $set->{diff_config} || {};
    }
    return $rv;
}

1;
__DATA__
#!/usr/bin/perl
#
use strict;
use warnings;

use DBIx::Class::Migration::RunScript;


use [% schema %];
use Data::Dumper ;

my $routines = {
    "delete"    =>\&delete,
    "insert"    =>\&insert,
    "create"    =>\&create,
    "update"    =>\&update,
    "update_or_create"    =>\&update_or_create,
    "pre_sql_statement"        => \&pre_sql_statement
};

sub printDebug {

	print @_ if ($ENV{IF_MIGRATION_DEBUG});

}

sub sort_pk_numeric {
    my @nA = split(/-/,$a);
    my @nB = split(/-/,$b);
    my $i=0;
    my ($csa,$csb) = (0,0);
    for ($i=0; $i <= $#nA;$i++) {
        my ($fa,$fb) = ($nA[$i] || '',$nB[$i] || '');
        next if ( $fa !~ /^\d+$/ || $fb !~ /^\d+$/ );
        my ($la,$lb)=(length($fa),length($fb));
        my $ml = ( $la > $lb ) ? $la : $lb ; # ml = max length
        $csa .= sprintf("%0".$ml."s",$fa);
        $csb .= sprintf("%0".$ml."s",$fb);
    }

    $csa cmp $csb;
}

sub insert {
    my ($self,$class,$inData,$options) = @_;

    my $schema = [% schema %]->connect({dbh_maker=>sub { return $self->dbh}});
    foreach my $pk (sort sort_pk_numeric (keys(%{$inData}))) {
        printDebug "  - inserting $pk\n";
        my $rs = $schema->resultset($class);
        $rs->find_or_create($inData->{$pk});
     }
}

sub create {
    my ($self,$class,$inData,$options) = @_;

    my $schema = [% schema %]->connect({dbh_maker=>sub { return $self->dbh}});
    foreach my $pk (sort sort_pk_numeric (keys(%{$inData}))) {
        printDebug "  - creating $pk\n";
        my $data = $inData->{$pk};
        $schema->resultset($class)->create($inData->{$pk});
     }
}

sub delete  {
    my ($self,$class,$inData,$options) = @_;

    my $schema = [% schema %]->connect({dbh_maker=>sub { return $self->dbh}});

    foreach my $pk (sort sort_pk_numeric keys(%{$inData})) {
        printDebug "  - deleting $pk\n";
        my $sd = prepare_search_data(
            $self,
            $inData->{$pk},
            $options
        );
        my $rs = $schema->resultset($class)->find($sd);
        if ($rs) {
            $rs->delete;
        } else {
            printDebug "   - Cannot find Element for $pk\n";
        }
     }

}
sub update  {
    my ($self,$class,$inData,$options) = @_;

    my $schema = [% schema %]->connect({dbh_maker=>sub { return $self->dbh}});

    foreach my $pk (sort sort_pk_numeric keys(%{$inData})) {
        printDebug "  - updating $pk\n";
        my $sd = prepare_search_data(
            $self,
            $inData->{$pk},
            $options
        );

        my $rs = $schema->resultset($class)->find($sd);

        if (! $rs ) {
            printDebug "   - Not found\n";
        } else {
            printDebug "   - updating ...\n";
            $rs->update($inData->{$pk});
        }

     }
}

sub update_or_create {
    my ($self,$class,$inData,$options) = @_;
    my $schema = [% schema %]->connect({dbh_maker=>sub { return $self->dbh}});
    my $rs = $schema->resultset($class);

    foreach my $pk (sort sort_pk_numeric (keys(%{$inData}))) {
        printDebug "  - update_or_create $pk\n";
        my $sd = prepare_search_data(
            $self,
            $inData->{$pk},
            $options
        );
        my $row = $rs->find($sd);
        if (! $row ) {
            printDebug "   - creating ...\n";
            $rs->create($inData->{$pk});
        } else {
            printDebug "   - updating ...\n";
            $row->update($inData->{$pk});
        }

     }
}

sub prepare_search_data {
    my ($self,$data,$options) = @_;

    return $data if (ref($options->{search_fields}) ne 'ARRAY' );
    my $sf = $options->{search_fields};
    my $tmpData={};

    foreach my $field (@{$sf}) {
        $tmpData->{$field} = $data->{$field}
    }
    return $tmpData;
}


sub pre_sql_statement {
    my ($self,$class,$stmt) = @_;

    $self->dbh->do($stmt);

}

migrate {
    my $self = shift;
    my [% VAR1 %]

    printDebug "migrate ... \n";

    foreach my $set_name (keys(%{$VAR1})) {
        printDebug "- use Set $set_name\n";
        foreach my $class (keys(%{$VAR1->{$set_name}})) {
            next if ($class eq 'options');
            foreach my $meth (qw/pre_sql_statement delete create insert update update_or_create/) {
                next if ( ! $VAR1->{$set_name}->{$class}->{$meth} );
                $routines->{$meth}->(
                        $self,
                        $class,
                        $VAR1->{$set_name}->{$class}->{$meth},
                        $VAR1->{$set_name}->{options}->{$meth}
                );
            }
        }
    }

    printDebug "... migration finished\n";

}

