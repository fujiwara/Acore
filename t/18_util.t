# -*- mode:perl -*-
use strict;
use Test::More tests => 2;

BEGIN {
    use_ok 'Acore::WAF::Util';
};

can_ok( "Acore::WAF::Util", qw/ adjust_request_mod_perl adjust_request_fcgi /);
