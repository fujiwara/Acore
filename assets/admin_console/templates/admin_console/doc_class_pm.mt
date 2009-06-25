? my $c = $_[0];
package <?=r $c->stash->{class} ?>;
use strict;
use warnings;
use Any::Moose;
use utf8;

? for my $name ( @{ $c->stash->{names} } ) {
has "<?=r $name ?>" => ( is => "rw" );
? }

extends 'Acore::Document::Templatize';

use constant create_template => "<?=r $c->stash->{class_filename} ?>_create_form.mt";
use constant edit_template   => "<?=r $c->stash->{class_filename} ?>_create_form.mt";

=for comment

sub execute_on_create {
    my ($self, $c) = @_;
}

sub execute_on_update {
    my ($self, $c) = @_;
}

=cut

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__
