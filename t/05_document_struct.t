# -*- mode:perl -*-
use strict;
use Test::More tests => 13;
use Data::Dumper;
use Clone qw/ clone /;

BEGIN {
    use_ok "Acore";
    use_ok 'Acore::Document::Struct';
};

{
    my $d = Acore::Document::Struct->new({
        path         => "/bar/baz",
        content_type => "text/plain",
        title        => "foo",
        description  => "bar",
        body         => {
            key1 => "value1",
            key2 => "value2",
        },
    });
    is $d->path         => "/bar/baz", "path is set";
    is $d->content_type => "text/plain", "content_type is set";
    isa_ok $d => "Acore::Document";
    isa_ok $d => "Acore::Document::Struct";
    isa_ok $d->created_on => $Acore::DateTime::DT_class;
    isa_ok $d->updated_on => $Acore::DateTime::DT_class;

    is $d->title       => "foo", "title";
    is $d->description => "bar", "description";
    is_deeply $d->body => { key1 => "value1", key2 => "value2" };

    like $d->html_form_to_create => qr{<input type="text"};
    like $d->html_form_to_update => qr{<input type="text"};
}

