package Acore::Document::Struct;

use strict;
use warnings;
use Any::Moose;

extends 'Acore::Document';

has title => ( is => "rw" );
has body  => ( is => "rw" );
has description => ( is => "rw" );

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;
