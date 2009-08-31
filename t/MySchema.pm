package t::MySchema;
use strict;
use base qw/ DBIx::Class::Schema::Loader /;
__PACKAGE__->loader_options(
    relationships => 1,
    debug         => 0,
);
1;
