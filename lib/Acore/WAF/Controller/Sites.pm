package Acore::WAF::Controller::Sites;
use strict;
use warnings;
use Scalar::Util qw/ blessed /;

sub page {
    my ($self, $c, $args) = @_;

    my $page = $args->{page} || "";
    $page .= "index" if $page =~ m{/\z};

    if ($page =~ m{[^\w./-]}) {
        $c->error( 404 => "invalid page name: $page" );
    }
    my $template = $page ? "$page.mt" : "index.mt";
    eval {
        $c->render("sites/$template");
    };
    my $error = $@;
    if ($error=~ /could not find template file/) {
        $c->error( 404 => $@ );
    }
    elsif (blessed $error && $error->isa('CGI::ExceptionManager::Exception') ) {
        $c->detach;
    }
    elsif ($error) {
        $c->error( 500 => $error );
    }
}

sub path {
    my ($self, $c, $args) = @_;
    my ($page, @path) = split "/", ($args->{page} || "");
    $c->forward( $self => "page", { page => $page } );
}

1;

__END__

=head1 DISPATCH TABLE

    connect "",
        { controller => "Acore::WAF::Controller::Sites", action => "page" };
    
    # /foo/bar/baz => templates/sites/foo/bar/baz.mt
    connect ":page",
        { controller => "Acore::WAF::Controller::Sites", action => "page" };
    
    # /foo/bar/baz => templates/sites/foo.mt
    connect ":page",
        { controller => "Acore::WAF::Controller::Sites", action => "path" };

