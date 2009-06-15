package Acore::WAF::Controller::Sites;
use strict;
use warnings;

sub page {
    my ($self, $c, $args) = @_;

    my $page = $args->{page} || "";
    $page .= "index" if $page =~ m{/\z};

    if ($page =~ m{[^\w.-]}) {
        $c->error( 404 => "invalid page name: $page" );
    }
    my $template = $page ? "$page.mt" : "index.mt";
    eval {
        $c->render("sites/$template");
    };
    if ($@ =~ /could not find template file/) {
        $c->error( 404 => $@ );
    }
    elsif ($@) {
        $c->error( 500 => $@ );
    }
}

1;

__END__

=head1 DISPATCH TABLE

    connect "",
        { controller => "Acore::WAF::Controller::Sites", action => "page" };
    connect ":page",
        { controller => "Acore::WAF::Controller::Sites", action => "page" };


