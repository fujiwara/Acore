# -*- mode:perl -*-
use strict;
use Test::More tests => 15;
use Data::Dumper;
use Clone qw/ clone /;

BEGIN {
    use_ok "Acore";
    use_ok 'Acore::Document';
};

{
    my $d = Acore::Document->new({
        content_type => "text/plain",
        path         => "/foo/bar",
    });
    is $d->path         => "/foo/bar", "path is set";
    is $d->content_type => "text/plain", "content_type is set";
    isa_ok $d => "Acore::Document";
    isa_ok $d->created_on => "DateTime";
    isa_ok $d->updated_on => "DateTime";

    my $dt_c = clone($d->created_on);
    my $dt_u = clone($d->updated_on);

    ok $d->can('to_object'), "can to_object";
    my $o = $d->to_object;
    like $o->{created_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated created_on";
    like $o->{updated_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated updated_on";

    my $d2 = Acore::Document->from_object($o);
    isa_ok $d2 => "Acore::Document";
    isa_ok $d2->created_on => "DateTime";
    isa_ok $d2->updated_on => "DateTime";

    is_deeply $d2->created_on => $dt_c, "same datetime object";
    is_deeply $d2->updated_on => $dt_u, "same datetime object";
}

