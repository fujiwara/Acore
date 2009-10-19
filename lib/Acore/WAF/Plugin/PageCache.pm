package Acore::WAF::Plugin::PageCache;
use strict;
use warnings;
use Any::Moose "::Role";
use HTTP::Date;

requires "cache";

around _dispatch => sub {
    my $orig = shift;
    my ($c)  = @_;
    my $req  = $c->request;

    return $orig->(@_) if $req->method ne "GET"; # ignore unless GET

    my $uri  = $c->request_for_dispatcher->uri;
    my $path = ref($uri) ? $uri->path : $uri;
    $path =~ s{^/}{};

    my $config = $c->config->{page_cache} || $c->config->{"Plugin::PageCache"};
    my $regexp = $config->{path_regexp};

    if ( $path !~ /$regexp/ ) {
        $c->log->debug("PageCache disabled by $path =~ /$regexp/");
        return $orig->(@_);
    }

    my $cache = $c->cache;
    my $key   = $req->uri;

    $c->log->debug("PageCache: match path for cache. %s", $req->uri);
    if ( my $res = $cache->get($key) ) {
        $c->log->debug("PageCache: hit from cache.");
        $res->header("X-PageCache" => "hit");

        my $modified = $res->header("Last-Modified");
        my $since    = $req->header("If-Modified-Since");
        if ( $modified && $since && $modified eq $since ) {
            $c->log->debug("Not modified since %s", $modified);
            $res->status(304);
            $res->body("");
        }
        $c->response($res);
        return;
    }

    # do _dispatch
    $orig->(@_);
    my $res = $c->res;

    my $expires = $config->{expires} || 60;
    for my $name ( qw/ Cache-Control Pragma / ) {
        my $header = $res->header($name);
        next unless $header;
        if ( $header =~ /(?:no-store|no-cache|private)/ ) {
            $c->log->debug(
                "cache is not stored by response header. %s: %s",
                $name, $header,
            );
            $res->header("X-PageCache" => "miss,no-store");
            return $res;
        }
        $expires = $1 if $header =~ /max-age=(\d+)/;
    }

    $c->log->debug("cache set key=$key expires: $expires sec.");
    $c->cache->set( $key => $res, $expires )
        or $c->log->error("cache set failed.");

    $res->header("X-PageCache" => "miss");

    return $res;
};

1;

__END__

=head1 NAME

Acore::WAF::Plugin:PageCache - AnyCMS page cache plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ Cache PageCache /);
 $config->{cache} = ...
 $config->{page_cache} = {
     path_regexp => "(?:foo|bar)/",  # match for Dispatcher connect path
     expires     => 300,             # default 60 sec
 };

=head1 DESCRIPTION

Acore page cache plugin.


=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
