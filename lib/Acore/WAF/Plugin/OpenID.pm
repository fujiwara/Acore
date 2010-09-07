package Acore::WAF::Plugin::OpenID;

use strict;
use warnings;
use Any::Moose "::Role";

sub authenticate_openid {
    my $c = shift;

    my $claimed_uri = $c->req->param('openid_identifier');
    unless ($claimed_uri or $c->req->param('openid-check')) {
        return;
    }

    require Net::OpenID::Consumer;
    require LWPx::ParanoidAgent;

    my $version = Net::OpenID::Consumer->VERSION;
    if ($version < 1.03) {
        $c->log->warning("Net::OpenID::Consumer->VERSION $version, Can't use OpenID 2.0 (e.g. yahoo.co.jp or mixi.jp ...)");
    }

    my $config  = $c->config->{openid};
    my $secret  = $config->{consumer_secret} || do {
        my $s = join '+', __PACKAGE__,
            ref( $c ), sort keys %{ $c->config };
        $s = substr($s, 0, 255) if length $s > 255;
        $s;
    };
    $c->log->debug("comsumer secret=$secret");
    my $ua      = LWPx::ParanoidAgent->new;
    my $args    = {};
    $args->{$_} = $c->req->param($_) for $c->req->param;
    $c->log->debug( Data::Dumper::Dumper $args );

    my $csr = Net::OpenID::Consumer->new(
        ua              => $ua,
        args            => $args,
        consumer_secret => $secret,
    );
    if ( $c->can("cache") ) {
        $csr->cache( $c->cache );
    }
    else {
        $c->log->warning("no \$c->cache, but it recommended for Net::OpenID::Consumer.");
    }

    local *LWP::Debug::debug = sub { $c->log->debug("LWP::Debug::debug @_") };
    local *LWP::Debug::trace = *LWP::Debug::debug;

    if ($claimed_uri) {
        my $current = $c->uri_for( $c->req->uri->path );

        my $identity = eval { $csr->claimed_identity($claimed_uri) }
            or $c->error( 500 => "OpenID error: " . $csr->err );

        my $check_url = $identity->check_url(
            return_to      => $current . '?openid-check=1',
            trust_root     => $current,
            delayed_return => 1,
        );
        $c->redirect($check_url);
        $c->detach;
    }
    elsif ($c->req->param('openid-check')) {
        $c->log->debug("openid-check");
        if (my $setup_url = $csr->user_setup_url) {
            $c->log->debug("setup_url=$setup_url");
            $c->redirect($setup_url);
            $c->detach;
        }
        elsif ($csr->user_cancel) {
            $c->log->error('user_cancel');
        }
        elsif (my $identity = $csr->verified_identity) {
            $c->log->debug("verified_identity");
            my $user = +{ map { $_ => scalar $identity->$_ }
                    qw(url display rss atom foaf declared_rss
                       declared_atom declared_foaf foafmaker) };
            $c->user($user);
            return $user;
        }
        else {
            $c->error( 500 => "Error validating identity: " . $csr->err );
        }
    }

    return;
}

1;

__END__

=head1 NAME

Acore::WAF::Plugin::OpenID

=head1 SYNOPSIS

 package YourApp::Dispatcher;
 connect "openid", to controller "Root" => "openid";

 package YourApp::Controller::Root;
 sub openid {
     my ($self, $c) = @_;
     if ( $c->authenticate_openid ) {
         $c->user; # open id user info
     }
     else {
         $c->render('openid_form.mt');
     }
 }

 <form action="<?= $c->uri_for('/openid') ?>" method="post">
   <input type="text" name="openid_identifier" />
 </form>

=head1 NOTE

Using Plugin::Cache is recommended.
