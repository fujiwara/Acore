? my $c = $_[0];
package <?=r $c->stash->{class} ?>;
use strict;
use warnings;
use Any::Moose;
use utf8;

extends 'Acore::Document::Templatize';

use constant create_template => "<?=r $c->stash->{class_filename} ?>_create_form.mt";
use constant edit_template   => "<?=r $c->stash->{class_filename} ?>_create_form.mt";

1;
