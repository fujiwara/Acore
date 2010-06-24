# -*- mode:perl -*-
use strict;
use Test::More;
use Data::Dumper;

BEGIN {
    use_ok 'Acore::LoadModules';
};

ok $INC{$_} => "$_ is loaded"
    for qw{ Acore.pm DBIx/CouchLike.pm
            Plack/Request.pm Any/Moose.pm JSON/XS.pm Path/Class.pm
          };

done_testing;
