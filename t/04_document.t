# -*- mode:perl -*-
use strict;
use Test::More tests => 13;
use Data::Dumper;
use Clone qw/ clone /;

BEGIN {
    use_ok "Acore";
    use_ok 'Acore::Document';
};

{
    my $d = Acore::Document->new({ content_type => "text/plain" });
    is $d->content_type => "text/plain", "content_type is set";
    isa_ok $d => "Acore::Document";
    isa_ok $d->created_on => "DateTime";
    isa_ok $d->updated_on => "DateTime";

    my $dt_c = clone($d->created_on);
    my $dt_u = clone($d->updated_on);

    ok $d->can('_before_serialize'), "can _before_serialize";
    $d->_before_serialize;
    like $d->{created_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated created_on";
    like $d->{updated_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated updated_on";

    $d->_after_deserialize;
    isa_ok $d->created_on => "DateTime";
    isa_ok $d->updated_on => "DateTime";

    is_deeply $d->created_on => $dt_c, "same datetime object";
    is_deeply $d->updated_on => $dt_u, "same datetime object";
}

