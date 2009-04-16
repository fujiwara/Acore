package Acore::Document::Struct;

use strict;
use warnings;
use base qw/ Acore::Document /;

__PACKAGE__->mk_accessors(qw/ title description body /);

1;
