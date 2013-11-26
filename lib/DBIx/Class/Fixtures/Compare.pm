package DBIx::Class::Fixtures::Compare;

use Moose;

use Path::Class::File;
use FindBin;
use Data::Dumper;
use Test::More;

my $DEBUG = $ENV{DBIC_FIXTURES_DEBUG} || 0;

=head1 ACCESSORS/METHODS

=head2 from - Hash which contains source fixtures

=head2 to - Hash which contains destination fixtures

=head2 compare - compare "from" and "to"

=cut



has 'from' => (is=>'ro',isa=>'HashRef');
has 'to' => (is=>'ro',isa=>'HashRef');
has 'config' => (is=>'ro',isa=>'HashRef');
has '__result' => (is=>'ro',isa=>'HashRef',default=>sub { {} });

sub printDebug { map { print "$_\n" } @_ if $DEBUG }

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
    my $strat   = $self->config->{$table}->{update_strategy} || 'update';
    if ( $self->config->{$table}->{pre_sql_statement} ) {
        $result->{pre_sql_statement} = $self->config->{$table}->{pre_sql_statement};
    }
    foreach my $pk (keys(%{$from})) {
        if ( $to->{$pk} ) {
            my $cs = $self->__compare_record($table,$pk); # cs = compared set
            if ($cs) {
                if ( $strat ne 'recreate' ) {
                    $result->{$strat}->{$pk} = $cs;
                } else {
                    $result->{'delete'}->{$pk} = $from->{$pk};
                    $result->{'insert'}->{$pk} = $to->{$pk};
                }

            }

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
    my $rv = undef;
    my $config = $self->config->{$table};

    no warnings 'uninitialized';
    while ( my ($key,$val) = each(%{$from})) {
       next if ( $key ~~ @{$config->{exclude_fields}} );
       if ( $to->{$key} ne $val ) {
            printDebug(
                "\$from->{$key} differs from \$to->{$key}",
                "from val: '$from->{$key}'",
                "  to val: '$to->{$key}'",
            );
            $rv = $to;
       }
    }
    while ( my ($key,$val) = each(%{$to})) {
       next if ( $key ~~ @{$config->{exclude_fields}} );
       if ( $from->{$key} ne $val ) {
            printDebug(
                "\$to->{$key} differs from \$from->{$key}",
                "  to val: '$to->{$key}'",
                "from val: '$from->{$key}'",
            );
            $rv = $to;
       }
    }
    use warnings 'all';
    return $rv;

}

1;
