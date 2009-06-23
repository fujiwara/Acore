package Acore::Dispatcher;
use strict;
use warnings;
use base 'HTTPx::Dispatcher';
use HTTPx::Dispatcher::Rule;
use Exporter 'import';
our @EXPORT = qw/connect match uri_for/;

*connect = *HTTPx::Dispatcher::connect;
*match   = *HTTPx::Dispatcher::match;
*uri_for = *HTTPx::Dispatcher::uri_for;

package HTTPx::Dispatcher::Rule;
use Carp;

no warnings "redefine";

sub _filter_response {
    my ($self, $input) = @_;
    my $output = {};
    for my $key (qw/controller action/) {
        $output->{$key} = delete $input->{$key} or croak "missing $key";
    }
    $input->{root}  = $self->{root};
    $output->{args} = $input;
    return $output;
}

1;
