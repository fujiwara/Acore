# -*- mode:perl -*-
use strict;
use Test::More;
use Test::Exception;
use Scalar::Util qw/ refaddr /;
use utf8;

BEGIN {
    use_ok 'Acore::Util';
};

eval "use Acore::Util qw/clone/";
{
    my $foo = { foo => [ 1, 2, { bar => "baz" } ] };
    is_deeply $foo => clone($foo), "clone";
    isnt refaddr("$foo"), refaddr( clone($foo) ), "other instance";
}

done_testing;
