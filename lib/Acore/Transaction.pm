package Acore::Transaction;

use strict;
use warnings;

sub new {
    my ($class, $acore) = @_;
    $acore->txn_begin;
    return bless [ 0, $acore ], $class;
}

sub commit {
    my $self = shift;
    $self->[1]->txn_commit;
    $self->[0] = 1;
}

sub rollback {
    my $self = shift;
    $self->[1]->txn_rollback;
    $self->[0] = 1;
}

sub DESTROY {
    my $self = shift;
    return if $self->[0]; # finished

    {
        local $@;
        eval { $self->[1]->txn_rollback };
        my $rollback_exception = $@;
        if($rollback_exception) {
            die "Rollback failed: ${rollback_exception}";
        }
    }
}

1;
