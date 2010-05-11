package t::WAFTest::Model::Skinny::Schema;
use strict;
use DBIx::Skinny::Schema;

install_table foo => schema {
    pk      qw/ id /;
    columns qw/ id foo /;
};

1;
