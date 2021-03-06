package Acore::WAF::Util;

use strict;
use warnings;
require Exporter;
our @ISA         = qw(Exporter);
our @EXPORT_OK   = qw( to controller bundled class extra );
our %EXPORT_TAGS = ( dispatcher => [qw/ to controller bundled class extra /] );

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

sub extra($) {                                   ## no critic
    my ($type, $name) = split /::/, $_[0];
    "AcoreX::${type}::Controller::${name}";
}

{
    package Acore::WAF::Util::RequestForDispatcher;
    use Any::Moose;

    has uri    => ( is => "rw" );
    has method => ( is => "rw" );

    sub new_from_request {
        my $class = shift;
        my $req   = shift;

        my ($location, $path);
        # for Acore::WAF::Request
        $path     = $req->env->{PATH_INFO};
        $location = $req->env->{SCRIPT_NAME};
        $class->new({
            method => $req->method,
            uri    => $path,
        });
    }
}

1;

__END__
