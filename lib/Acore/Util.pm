package Acore::Util;

use strict;
use warnings;
use Exporter qw/ import /;

our @EXPORT_OK = qw/ clone /;

BEGIN {
    eval "use Clone()"; ## no critic
    if ($@) {
        require Storable;
        *clone = \&Storable::dclone;
    }
    else {
        *clone = \&Clone::clone;
    }
};

1;

__END__

=head1 NAME

Acore::Util - Acore util functions

=head1 SYNOPSIS

  use Acore::Util qw/ clone /;

=head1 DESCRIPTION

=head1 FUNCTIONS

=over 4

=item clone

Clone::clone or Storable::dclone;

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

L<Clone>, L<Storable>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


