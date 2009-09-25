package Acore::WAF::Plugin::FormValidator;

use strict;
use warnings;
use FormValidator::Lite;
use Any::Moose "::Role";

FormValidator::Lite->load_constraints(qw/Japanese/);

has form => (
    is      => "rw",
    lazy    => 1,
    default => sub {
        my $c = shift;
        FormValidator::Lite->new( $c->request );
    },
);

1;
__END__

=head1 NAME

Acore::WAF::Plugin::FormValidator - AnyCMS formvalidator plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ FormValidator /);

 package YourApp::Controller;
 sub foo {
     my ($self, $c) = @_;
     $c->form->check(
         id => [qw/ NOT_NULL INT /],
     );
     if ($c->form->has_errror) {
     }
 }

=head1 DESCRIPTION

Acore form validator plugin by FormValidator::Lite

=head1 EXPORT METHODS

=over 4

=item form

An instance of FormValidator::Simple.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

FormValidator::Lite

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
