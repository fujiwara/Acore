package Acore::WAF::Model;

use strict;
use warnings;

1;

__END__

=head1 NAME

Acore::WAF::Model - empty class (POD only)

=head1 SYNOPSYS

 package YourApp::Model::Foo;
 use Any::Moose;  # if require instantination
 sub setup {
     my ($self, $c) = @_;
     # setup yourself...
 }
 sub something {
 }

 package YourApp::Controller::Bar;
 sub bar {
     my ($self, $c, $args) = @_;
     $c->model("Foo")->something;
 }

