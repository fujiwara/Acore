# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Storable qw/ dclone /;

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
    isa_ok $d->created_on => $Acore::DateTime::DT_class;
    isa_ok $d->updated_on => $Acore::DateTime::DT_class;
    ok $d->as_string;

    my $dt_c = dclone($d->created_on);
    my $dt_u = dclone($d->updated_on);

    ok $d->can('to_object'), "can to_object";
    my $o = $d->to_object;
    like $o->{created_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated created_on";
    like $o->{updated_on} => qr/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:Z|[+-][0-9:]+)$/, "formated updated_on";

    my $d2 = Acore::Document->from_object($o);
    isa_ok $d2 => "Acore::Document";
    isa_ok $d2->created_on => $Acore::DateTime::DT_class;
    isa_ok $d2->updated_on => $Acore::DateTime::DT_class;

    is_deeply $d2->created_on => $dt_c, "same datetime object";
    is_deeply $d2->updated_on => $dt_u, "same datetime object";
}

{
    my $d = Acore::Document->new({
        foo => 123,
    });
    is $d->{foo}    => 123, "hashref";
    is $d->foo      => 123, "autoload method get";
    is $d->foo(234) => 234, "autoload method set";
    is $d->{foo}    => 234, "hashref";

    is $d->bar(333) => 333;
    is $d->bar      => 333;
    is $d->{bar}    => 333;
}


{
    my $d = Acore::Document->new({
        id  => 1,
        a   => 2,
        b   => 3,
    });
    is $d->id => 1;
    is $d->a  => 2;
    is $d->b  => 3;

    ok $d->update_from_hashref({ a => 4, c => 5 });
    is $d->id => 1;
    is $d->a  => 4;
    is $d->b  => undef;
    is $d->c  => 5;
}

{
    my $d = Acore::Document->new({
        id => 1,
        html => {
            head => {
                title => "TITLE",
            },
            body => {
                list => [qw/ A B C /],
            },
        },
    });
    ok $d->xpath, "xpath ok";
    is $d->xpath->get("/id") => 1, "/id";
    is $d->xpath->get("/html/head/title") => "TITLE";
    is $d->xpath->get("/html/body/list[0]") => "A";
    is $d->xpath->get("/html/body/list[1]") => "B";
    is $d->xpath->get("/html/body/list[2]") => "C";
    is $d->xpath->get("/html/body/list[3]") => undef;
    is $d->xpath->get("/xxx") => undef;
    $d->{xxx} = "XXX";
    is $d->xpath->get("/xxx") => "XXX";

    ok $d->xpath->set('/xxx' => 'YYY');
    is $d->xpath->get("/xxx") => "YYY";
    ok $d->xpath->set("/html/body/list[1]" => "BBB");
    is $d->xpath->get("/html/body/list[0]") => "A";
    is $d->xpath->get("/html/body/list[1]") => "BBB";
    is $d->xpath->get("/html/body/list[2]") => "C";

    ok $d->xpath->set("/html/head/title" => "NOTITLE");
    is $d->xpath->get("/html/head/title") => "NOTITLE";
}

{
    my $d = Acore::Document->new({});
    ok $d->set('/xxx' => 'YYY');
    ok $d->xpath->set("/html/body/list[1]" => "BBB");
    ok $d->xpath_set("/html/head/title" => "NOTITLE");
    is_deeply $d->{"xxx"} => "YYY";
    is_deeply $d->{"html"} => {
        body => {
            list => [ undef, "BBB" ],
        },
        head => { title=> "NOTITLE" },
    };

    # alias
    is $d->get("/html"), $d->xpath_get("/html");
    is $d->get("/html"), $d->xpath->get("/html");
}

done_testing;
