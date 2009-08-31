package t::WAFTest::Model::DBIC;
use strict;
use Any::Moose;
extends 'Acore::WAF::Model::DBIC';
my $Instance;
override new => sub { $Instance ||= super() }; # be singleton..
1;
