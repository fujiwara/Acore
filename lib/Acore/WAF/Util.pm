package Acore::WAF::Util;

use strict;
use warnings;
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw( to controller bundled class );
our %EXPORT_TAGS = ( dispatcher => [qw/ to controller bundled class /] );

sub to {
    my ($controller, $action, @args) = @_;
    my $r = { @args };
    $r->{controller} = $controller if defined $controller;
    $r->{action}     = $action     if defined $action;
    $r;
}

sub class($) { $_[0] }                            ## no critic

sub bundled($) { "Acore::WAF::Controller::$_[0]"} ## no critic

sub controller($) {                               ## no critic
    ( my $class = (caller)[0] ) =~ s/::Dispatcher$//;
    "${class}::Controller::$_[0]";
}

sub adjust_request_mod_perl {
    my ($class, $req) = @_;

    my $location = $req->_connection->{apache_request}->location || '/';
    $location   .= '/' if $location !~ m{/$};

    $req->uri->base->path_query($location);
    $req->location($location);

    return $req;
}

sub adjust_request_fcgi {
    my ($class, $req) = @_;
    $req->location( $req->uri->base->path );
    return $req;
}

{
    package ## hide for pause
        HTTP::Engine::Request;
    sub location {
        my $self = shift;
        if (@_) {
            $self->{location} = shift;
        }
        $self->{location};
    }
}

{
    package Acore::WAF::Util::RequestForDispatcher;
    use Any::Moose;

    has uri    => ( is => "rw" );
    has method => ( is => "rw" );
}

1;

__END__
