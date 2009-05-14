package Acore::WAF::Plugin::FormValidator;

use strict;
use warnings;
use FormValidator::Lite;
require Exporter;
our @EXPORT = qw/ form /;

FormValidator::Lite->load_constraints(qw/Japanese/);

sub setup {
    my ($class, $app) = @_;
}

sub form {
    my $c = shift;
    $c->{_form} ||= FormValidator::Lite->new( $c->request );
    $c->{_form};
}

1;
