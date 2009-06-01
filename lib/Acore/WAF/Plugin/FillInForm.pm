package Acore::WAF::Plugin::FillInForm;

use strict;
use warnings;
require Exporter;
our @EXPORT = qw/ fillform /;

sub fillform {
    my $c   = shift;
    my $obj = shift || $c->request;

    my $body = $c->res->body;
    return unless defined $body;

    require HTML::FillInForm;
    $body = HTML::FillInForm->fill(\$body, $obj);
    $c->res->body($body);
}

1;
__END__

=head1 NAME

Acore::WAF::Plugin::FillInForm - AnyCMS FillInForm plugin

=head1 SYNOPSIS

 YourApp->setup(qw/ FillInForm /);

 package YourApp::Controller;
 sub fill {
     my ($self, $c) = @_;
     $c->render('form.mt');
     $c->fillform; # Fill in form by $c->request
     # or $c->fillform(\%data);
 }


=head1 DESCRIPTION

Acore fill in form plugin.

=head1 EXPORT METHODS

=over 4

=item fillform

Fill a form.

=back

=head1 AUTHOR

FUJIWARA E<lt>fujiwara@topicmaker.comE<gt>

=head1 SEE ALSO

HTML::FillInForm

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
