package Acore::WAF::Controller::Sites;
use strict;
use warnings;
use Scalar::Util qw/ blessed /;

sub _do_auto {
    my ($self, $c, $args) = @_;
    $args->{auto}->( $self, $c, $args );
}

sub page {
    my ($self, $c, $args) = @_;

    my $page = $args->{page} || "";
    $page .= "index" if $page =~ m{/\z};

    if ($page =~ m{[^\w./-]}) {
        $c->error( 404 => "invalid page name: $page" );
    }
    my $ext      = $c->config->{sites}->{use_tt} ? "tt" : "mt";
    my $template = $page ? "$page.$ext" : "index.$ext";

    if ( ref $args->{auto} eq 'CODE' ) {
        $c->forward( $self, "_do_auto", $args )
            or return;
    }

    eval {
        $ext eq 'mt' ? $c->render("sites/$template", $args)
                     : $c->render_tt("sites/$template", $args);
    };
    my $error = $@;
    if ( $error =~ /could not find template file/    # for MT
      or $error =~ /file error - .* not found/    )  # for TT
    {
        $c->error( 404 => $@ );
    }
    elsif ( blessed $error && $error->isa('CGI::ExceptionManager::Exception') ) {
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

    connect "", to bundled "Sites" =>"page";
    
    # /foo/bar/baz => templates/sites/foo/bar/baz.mt
    connect ":page", to bundled "Sites" => "page";
    
    # /foo/bar/baz => templates/sites/foo.mt
    connect ":page", to bundled "Sites" => "path";

    # /foo/id=12345 => templates/sites/foo.mt  args.id=12345
    connect ":page/id=:id", to bundled "Sites" => "path";

    # run auto action
    $auto_action = sub {
        my ($self, $c, $args) = @_;
        # do something
        return 1;  # if ok
    };
    connect ":page", to bundled "Sites" => "page",
        args => { auto => $auto_action };
    connect ":page", to bundled "Sites" => "page",
        args => { auto => \&App::Controller::Root::_sites_auto };

    # for use Plugin::TT (file ext is .tt)
    
    App->setup(qw/ TT /);
    $config->{sites}->{use_tt} = 1;
