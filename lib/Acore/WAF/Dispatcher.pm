package Acore::WAF::Dispatcher;
use strict;
use warnings;
use HTTPx::Dispatcher::Rule;

{
    package HTTPx::Dispatcher::Rule;
    use Carp;

    no warnings "redefine";

    sub _filter_response {
        my ($self, $input) = @_;
        my $output = {};
        for my $key (qw/controller action/) {
            $output->{$key} = delete $input->{$key} or croak "missing $key";
        }
        $output->{args} = $input;
        if ( ref $self->{args} eq 'HASH' ) {
            for my $key ( keys %${ $self->{args} } ) {
                $output->{args}->{$key} ||= $self->{args}->{key};
            }
        }
        return $output;
    }
}

1;
