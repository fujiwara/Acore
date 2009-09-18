package Acore::WAF::Controller::Feed2Js;

use strict;
use warnings;
use utf8;

use LWP::UserAgent;
use XML::Feed;

sub fetch_uri {
    my ( $self, $c, $uri ) = @_;

    my $ua = LWP::UserAgent->new;
    $ua->env_proxy;
    $ua->timeout(5);
    return $ua->get($uri);
}

sub _e($;$);  ## no critic
*_e = \&Encode::decode_utf8;

sub _feed_to_hashref {
    my $feed = $_[0];
    my $obj;
    $obj->{$_} = _e $feed->$_
        for qw/ title base link tagline description
                author language copyright
                generator self_link /;
    $obj->{modified} = _e $feed->modified;
    $obj->{entries} = [
        map { _entry_to_hashref($_) } $feed->entries
    ];
    $obj;
}

sub _entry_to_hashref {
    my $entry = $_[0];
    my $e = {};
    $e->{$_} = _e $entry->$_
        for qw/ title base link category tags author id /;
    $e->{content}  = _e $entry->content->body;
    $e->{summary}  = _e $entry->summary->body;
    $e->{issued}   = _e $entry->issued;
    $e->{modified} = _e $entry->modified;
    $e;
}

sub process {
    my ( $self, $c ) = @_;

    my $res      = $c->forward( $self, "fetch_uri", $c->req->param("uri") );
    my $content  = $res ? $res->content : '';
    my $feed    = eval { XML::Feed->parse(\$content) }
                    or $c->error( 204 => "Can't parse feed. $@" );
    my $obj      = _feed_to_hashref($feed);

    my $view     = $c->view("JSON");
    my $encoding = $c->req->param("encoding") || "utf-8";

    $view->encoding($encoding)
        if Encode::find_encoding($encoding);

    $c->forward( $view => "process", $obj );
}


1;

__END__

=head1 DISPATCH TABLE

    connect "feed2js", to bundled "Feed2Js" => "process";
