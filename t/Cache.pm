package t::Cache;

use strict;
use warnings;
use base qw/ Cache::MemoryCache /;
our $debug = 0;
sub set {
    my $self = shift;
    warn "cache set @_\n" if $debug;
    $self->SUPER::set(@_);
}

sub get {
    my $self = shift;
    warn sprintf "cache get @_ \n" if $debug;
    $self->SUPER::get(@_);
}

sub remove {
    my $self = shift;
    warn "cache remove @_\n" if $debug;
    $self->SUPER::remove(@_);
}

1;
