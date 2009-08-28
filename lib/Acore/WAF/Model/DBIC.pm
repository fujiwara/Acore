package Acore::WAF::Model::DBIC;

use strict;
use Any::Moose;
use DBIx::Class::Schema;

has schema => (
    is         => "rw",
    lazy_build => 1,
);

has config => (
    is  => "rw",
    isa => "HashRef",
);

sub setup {
    my $self   = shift;
    my $c      = shift;
    $self->config( $c->config->{"Model::DBIC"} );
    $self;
}

sub _build_schema {
    my $self    = shift;
    my $config = $self->config;
    my $schema_class = $config->{schema_class};
    $schema_class->require or die "Can't require $schema_class: $!";
    $schema_class->connect(@{ $config->{connect_info} });
}

sub resultset {
    my $self = shift;
    $self->schema->resultset(@_);
}

*rs = \&resultset;

1;

__END__

=head1 NAME

Acore::WAF::Model::DBIC - DBIC model class

=head2 SYNOPSYS

 package YourApp::Model::DBIC;
 use Any::Moose;
 extends 'Acore::WAF::Model::DBIC';
 my $Instance;
 override new => sub { $Instance ||= super() }; # be singleton...

 package YourApp::Controller::Foo;
 $c->model("DBIC")->schema->resultset("Foo")->find($id);

 # YourApp.yaml
 "Model::DBIC":
    schema_class: YourSchema
    connect_info:
      - dbi:Pg:dbname=yourdb
      - user
      - pass
      - AutoCommit: 0
        RaiseError: 1
