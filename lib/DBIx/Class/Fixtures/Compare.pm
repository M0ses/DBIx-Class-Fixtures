package DBIx::Class::Fixtures::Compare;

use Moose;

use Path::Class::File;
use FindBin;
use Data::Dumper;
use Test::More;

#my $fixturesBasePath = "$FindBin::Bin/data/share/fixtures/";
#my $fContent={}; # fileContent
#
#foreach my $version (1,2) {
#    my $HASH1;
#    my $tmpFile=Path::Class::File->new("$fixturesBasePath/$version/User/data_set.fix");
#
#    $tmpFile->openr();
#    my $tmpContent = $tmpFile->slurp();
#
#    eval "$tmpContent";
#    $fContent->{$version}=$HASH1;
#
#}    
#
#my $upgrade = compareFixtures($fContent->{1},$fContent->{2});
#
#print Dumper($upgrade);
#
#exit 0;
#
#

=head1 ACCESSORS/METHODS

=head2 from - Hash which contains source fixtures

=head2 to - Hash which contains destination fixtures

=head2 compare - compare "from" and "to"

=cut



has 'from' => (is=>'ro',isa=>'HashRef');
has 'to' => (is=>'ro',isa=>'HashRef');
has '__result' => (is=>'ro',isa=>'HashRef',default=>sub { {} });

sub compare {
    my $self    = shift;    
    my $from    = $self->from;
    my $to      = $self->to;
    my $result  = $self->__result;

    map { $self->__compare_table($_) } keys(%{$from});

    return $result;    
}

sub __compare_table {
    my $self    = shift;
    my $table   = shift;
    my $from    = $self->from->{$table};
    my $to      = $self->to->{$table};
    my $result  = $self->__result->{$table} = {};

    foreach my $pk (keys(%{$from})) {
        if ( $to->{$pk} ) {
            my $cs = $self->__compare_record($table,$pk); # cs = compared set
            #$result->{'update'}->{$pk} = { from => $from->{$pk}, to =>$cs } if ($cs);
            $result->{'update'}->{$pk} = $cs  if ($cs);
        } else {        
            $result->{'delete'}->{$pk} = $from->{$pk} unless ($to->{$pk});
        }    
    }        
    foreach my $pk (keys(%{$to})) {
        $result->{'insert'}->{$pk} = $to->{$pk} unless ($from->{$pk});
    }        
}        

sub __compare_record {
    my $self    = shift;
    my $table   = shift;
    my $pk      = shift;
    my $from    = $self->from->{$table}->{$pk};
    my $to      = $self->to->{$table}->{$pk};

    while ( my ($key,$val) = each(%{$from})) {
       if ( $to->{$key} ne $val ) {
            # TODO: Log/debug print "$key from:$from->{$key} to:$to->{$key}\n";
            return $to
       }        
    }
    while ( my ($key,$val) = each(%{$to})) {
       if ( $from->{$key} ne $val ) {
            # TODO: Log/debug print "rev: $key from:$from->{$key} to:$to->{$key}\n";
            return $to
       }        
    }
    return undef;

}

1;
