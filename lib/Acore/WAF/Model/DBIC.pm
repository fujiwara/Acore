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

has _dbh_builder => (
    is  => "rw",
    isa => "CodeRef",
);

sub setup {
    my $self   = shift;
    my $c      = shift;
    my $config = $c->config->{"Model::DBIC"} || {};
    $self->config($config);

    unless ( $config->{connect_info} ) {
        $self->_dbh_builder(sub { $c->acore->dbh });
    }
    $self;
}

sub _build_schema {
    my $self = shift;

    my $config       = $self->config;
    my $schema_class = $config->{schema_class};
    $schema_class->require or die "Can't require $schema_class: $!";
    if ( $config->{connect_info} ) {
        $schema_class->connect(@{ $config->{connect_info} });
    }
    else {
        $schema_class->connect( $self->_dbh_builder );
    }
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

 # YourApp.yaml (reuse Acore->dbh)
 dsn:
   - dbi:Pg:dbname=yourdb
   - user
   - pass
   - AutoCommit: 0
     RaiseError: 1
 "Model::DBIC":
    schema_class: YourSchema

 # YourApp.yaml
 dsn:
   - dbi:Pg:dbname=acore_db
   - user
   - pass
   - AutoCommit: 0
     RaiseError: 1
 "Model::DBIC":
    schema_class: YourSchema
    connect_info:
      - dbi:Pg:dbname=schema_db
      - user
      - pass
      - AutoCommit: 0
        RaiseError: 1

