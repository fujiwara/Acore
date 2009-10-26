package t::WAFTest2;
use Any::Moose;

extends "t::WAFTest";
override "finalize" => sub {
    super();
    my $c = shift;
    $c->res->header("X-Override-Finalize" => "ok");
};

__PACKAGE__->setup();

{
    package t::WAFTest2::Dispatcher;
    use HTTPx::Dispatcher;
    use Acore::WAF::Util qw/:dispatcher/;

    my $controller = "t::WAFTest::Controller";
    connect "", to class $controller, "index";
}

1;
