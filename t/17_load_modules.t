# -*- mode:perl -*-
use strict;
use Test::More tests => 7;
use Data::Dumper;

BEGIN {
    use_ok 'Acore::LoadModules';
};

ok $INC{$_} => "$_ is loaded"
    for qw{ Acore.pm DBIx/CouchLike.pm
            HTTP/Engine.pm Any/Moose.pm JSON/XS.pm Path/Class.pm
          };
