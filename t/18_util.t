# -*- mode:perl -*-
use strict;
use Test::More;

BEGIN {
    use_ok 'Acore::WAF::Util';
};

can_ok( "Acore::WAF::Util", qw/ to class bundled controller extra /);

done_testing;
