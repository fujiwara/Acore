package Acore::WAF::Model::Skinny;

use strict;
use warnings;

sub setup {
    my $self   = shift;
    my $c      = shift;
    my $config = $c->config->{"Model::Skinny"} || {};

    $config->{connect_info}
        ? $self->connect_info( $config->{connect_info} )
        : $self->set_dbh( $c->acore->dbh );

    return $self;
}

1;

__END__

=head1 NAME

Acore::WAF::Model::Skinny - Skinny model class

=head2 SYNOPSYS

 package YourApp::Model::Skinny;
 use DBIx::Skinny;
 use Any::Moose;
 extends 'Acore::WAF::Model::Skinny';

 package YourApp::Controller::Foo;
 $c->model("Skinny")->single('test_t', { id => $id });

 # YourApp.yaml (reuse Acore->dbh)
 dsn:
   - dbi:Pg:dbname=yourdb
   - user
   - pass
   - AutoCommit: 0
     RaiseError: 1

 # YourApp.yaml
 dsn:
   - dbi:Pg:dbname=acore_db
   - user
   - pass
   - AutoCommit: 0
     RaiseError: 1
 "Model::Skinny":
   connect_info:
     dsn: dbi:Pg:dbname=schema_db
     username: username
     password: passward
     connect_options:
       AutoCommit: 0
       RaiseError: 1


