# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;

BEGIN {
    use_ok "Acore";
    use_ok 'Acore::Document::Templatize';
};

{
    my $d = Acore::Document::Templatize->new({
        foo => 1,
        bar => { baz => 3 },
        list => [ 1, 2, 3 ],
    });
    isa_ok $d => "Acore::Document::Templatize";
    isa_ok $d => "Acore::Document";
    can_ok $d, qw/ param html_form_to_create html_form_to_update
                   validate_to_create validate_to_update
                 /;
    is        $d->param('foo')  => 1;
    is_deeply $d->param('bar')  => { baz => 3 };
    is_deeply $d->param("/foo") => 1;
    is_deeply $d->param("/bar") => { baz => 3 };
    is_deeply $d->param("/bar/baz") => 3;
    is_deeply $d->param("/list")    => [ 1, 2, 3 ];
    is_deeply $d->param("/list[0]") => 1;
    is_deeply $d->param("/list[1]") => 2;
    is_deeply $d->param("/list[2]") => 3;
}

{
    package NullDocument;
    use Any::Moose;
    extends 'Acore::Document::Templatize';

    package main;

    my $d = NullDocument->new({
        foo => 1,
        bar => { baz => 3 },
        list => [ 1, 2, 3 ],
    });
    isa_ok $d => "Acore::Document::Templatize";
    isa_ok $d => "Acore::Document";
    isa_ok $d => "NullDocument";
    is $d->create_template => undef;
    is $d->edit_template   => undef;
    like $d->html_form_to_create => qr{^\n\? };
    like $d->html_form_to_update => qr{^\n\? };
}

{
    package MyDocument;
    use Any::Moose;
    extends 'Acore::Document::Templatize';

    sub create_template { "create.mt" };
    sub edit_template   { "edit.mt" };

    package main;

    my $d = MyDocument->new({
        foo => 1,
        bar => { baz => 3 },
        list => [ 1, 2, 3 ],
    });
    isa_ok $d => "Acore::Document::Templatize";
    isa_ok $d => "Acore::Document";
    isa_ok $d => "MyDocument";
    is $d->create_template => "create.mt";
    is $d->edit_template   => "edit.mt";
    like $d->html_form_to_create => qr{^\?= raw};
    like $d->html_form_to_update => qr{^\?= raw};
}

done_testing;
